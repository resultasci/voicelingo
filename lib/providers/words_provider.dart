import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// AppException hierarchy defines our own AuthException; hide Supabase's to avoid
// the ambiguous-import clash (PostgrestException etc. still come from Supabase).
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/errors/app_exception.dart';
import '../core/logger/app_logger.dart';
import '../core/network/connectivity_service.dart';
import '../core/offline/words_cache.dart';
import '../models/word.dart';
import '../services/notification_service.dart';
import '../core/ai/gemini_service.dart';
import 'profile_provider.dart';

final wordsProvider =
    StateNotifierProvider<WordsNotifier, AsyncValue<List<Word>>>(
  (ref) => WordsNotifier(ref),
);

/// Raised by [WordsNotifier.addWord] when a duplicate word/lang/user is
/// rejected by the Postgres unique index. Callers should catch and surface a
/// localized message — never bubble this to Sentry.
class DuplicateWordException extends AppException {
  final String word;
  DuplicateWordException(this.word)
      : super('Kelime zaten ekli: $word', code: 'duplicate_word');
}

class WordsNotifier extends StateNotifier<AsyncValue<List<Word>>> {
  WordsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
    // Hesap değişiminde (signIn/signOut) bellekteki liste önceki kullanıcıya
    // ait kalmasın — provider global olduğu için autoDispose ile çözülmüyor.
    _authSub = _db.auth.onAuthStateChange.listen((change) {
      final event = change.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut) {
        _cache = null;
        load(forceRefresh: true);
      }
    });
  }

  final Ref _ref;
  final _db = Supabase.instance.client;
  List<Word>? _cache;
  StreamSubscription<AuthState>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> load({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cache != null) {
        state = AsyncValue.data(_cache!);
        return;
      }
      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        _cache = const [];
        state = const AsyncValue.data([]);
        return;
      }

      // Stale-while-revalidate: Hive'da veri varsa spinner yerine onu hemen
      // göster, ağ cevabı gelince üzerine yaz. Soğuk açılışta liste anında dolar.
      final wordsCache = _ref.read(wordsCacheProvider);
      final hiveCached = wordsCache.readAll();
      if (hiveCached.isNotEmpty) {
        state = AsyncValue.data(hiveCached);
      } else {
        state = const AsyncValue.loading();
      }

      // Offline ise ağ timeout'u beklemeden bilinen state'te kal.
      final connectivity = _ref.read(connectivityServiceProvider);
      final online = await connectivity.isOnline();
      if (!online) {
        _cache = hiveCached;
        state = AsyncValue.data(hiveCached);
        return;
      }

      final data = await _db
          .from('words')
          .select(
              'id,user_id,word,translation,ease_factor,interval_days,repetitions,next_review,created_at,ipa,example_sentence')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final words = (data as List)
          .map((e) => Word.fromMap(e as Map<String, dynamic>))
          .toList();

      // No auto-seeding: new users start with an empty library and populate it
      // via manual add or AI topic generation (see generateAndAddWords).

      _cache = words;
      // Online fetch sonrası Hive cache'i yenile (fire-and-forget).
      unawaited(wordsCache.putAll(words));
      state = AsyncValue.data(words);
      _scheduleDailyReminderFor(words);
    } catch (e, st) {
      // Network hatası → cache'e düş (graceful degradation).
      try {
        final cached = _ref.read(wordsCacheProvider).readAll();
        if (cached.isNotEmpty) {
          _cache = cached;
          state = AsyncValue.data(cached);
          return;
        }
      } catch (_) {}
      state = AsyncValue.error(e, st);
    }
  }

  void _scheduleDailyReminderFor(List<Word> words) {
    final today = DateTime.now();
    final dueCount = words
        .where((w) =>
            w.nextReview.isBefore(today) ||
            w.nextReview.toIso8601String().split('T')[0] ==
                today.toIso8601String().split('T')[0])
        .length;
    NotificationService().scheduleDailyReviewReminder(dueCount);
  }

  Future<void> addWord(String word, String translation) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.warning('Kullanıcı oturumu bulunamadı, kelime eklenemiyor.',
          tag: 'WordsProvider');
      throw const AuthException('Oturum bulunamadı.');
    }

    final trimmedWord = word.trim();
    final lowerWord = trimmedWord.toLowerCase();

    // Büyük/küçük harf duyarlılığı olmadan yerel cache'te kelimeyi kontrol et.
    if (_cache != null) {
      final exists =
          _cache!.any((w) => w.word.trim().toLowerCase() == lowerWord);
      if (exists) {
        AppLogger.info('Kelime zaten kütüphanede mevcut: $trimmedWord',
            tag: 'WordsProvider');
        throw DuplicateWordException(trimmedWord);
      }
    }

    try {
      AppLogger.debug('Yeni kelime ekleniyor: $trimmedWord',
          tag: 'WordsProvider');
      final inserted = await _db
          .from('words')
          .insert({
            'user_id': userId,
            'word': trimmedWord,
            'translation': translation.trim(),
            'next_review': DateTime.now().toIso8601String().split('T')[0],
          })
          .select()
          .single();

      // Insert zaten yeni satırı döndürüyor — tüm tabloyu yeniden çekmek yerine
      // listenin başına ekle (created_at desc sıralamasıyla uyumlu).
      final newWord = Word.fromMap(inserted);
      _cache = [newWord, ...(_cache ?? state.value ?? const <Word>[])];
      state = AsyncValue.data(_cache!);
      unawaited(_ref.read(wordsCacheProvider).putAll(_cache!));
      AppLogger.info('Yeni kelime başarıyla eklendi: $trimmedWord',
          tag: 'WordsProvider');

      // Fire-and-forget enrichment: never block the user.
      final newId = inserted['id'] as String?;
      if (newId != null) {
        _enrichWord(id: newId, word: trimmedWord);
      }
    } on PostgrestException catch (e, st) {
      if (e.code == '23505') {
        AppLogger.warning(
            'Postgres veritabanında kelime zaten mevcut (Unique Constraint).',
            tag: 'WordsProvider');
        throw DuplicateWordException(trimmedWord);
      }
      AppLogger.error('Kelime eklenirken veritabanı hatası oluştu', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.error('Kelime eklenirken beklenmeyen bir hata oluştu', e, st);
      rethrow;
    }
  }

  /// Generates topic-based words via Gemini, inserts the de-duplicated set, then
  /// enriches a bounded subset (IPA + example). Returns how many words were
  /// actually inserted (after local + server-side dedup). May throw
  /// [AiException] (e.g. 429 daily limit) from the generation call — callers
  /// should catch and surface its localized message.
  Future<int> generateAndAddWords(String topic, int count) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Oturum bulunamadı.');
    }

    final profile = await _ref.read(profileProvider.future);
    final ai = _ref.read(geminiServiceProvider);
    final generated = await ai.generateWords(
      topic,
      count: count,
      targetLanguage: profile?.targetLanguage ?? 'en',
      userLevel: profile?.cefrLevel ?? 'A2',
    );
    if (generated.isEmpty) return 0;

    // Dedup against the local cache (case-insensitive) and within the batch,
    // mirroring addWord's pre-check. The DB unique index is the source of truth.
    final existing = (_cache ?? state.value ?? const <Word>[])
        .map((w) => w.word.trim().toLowerCase())
        .toSet();
    final seen = <String>{};
    final fresh = generated.where((g) {
      final k = g.en.trim().toLowerCase();
      if (k.isEmpty || existing.contains(k) || !seen.add(k)) return false;
      return true;
    }).toList();
    if (fresh.isEmpty) return 0;

    // Tek round-trip: RPC server tarafında ON CONFLICT DO NOTHING ile insert
    // eder, yalnız gerçekten eklenen satırları döndürür (partial dup'lar düşer).
    final rows = await _db.rpc('add_words_batch', params: {
      'p_words': [
        for (final g in fresh) {'word': g.en.trim(), 'translation': g.tr.trim()},
      ],
    });
    final inserted = (rows as List)
        .whereType<Map>()
        .map((r) => (id: r['id'] as String, word: r['word'] as String))
        .toList();

    _cache = null;
    await load(forceRefresh: true);

    // Enrich a bounded subset to stay well under the daily enrich cap (100/day).
    unawaited(_enrichBatch(inserted));
    return inserted.length;
  }

  Future<void> _enrichBatch(List<({String id, String word})> items) async {
    const maxEnrich = 10;
    var anyEnriched = false;
    for (final it in items.take(maxEnrich)) {
      // Update each word's DB row in place but DON'T reload per word — reloading
      // 10× back-to-back flickers the list to a spinner and wastes round-trips.
      anyEnriched =
          await _writeEnrichment(id: it.id, word: it.word) || anyEnriched;
      await Future.delayed(const Duration(milliseconds: 600)); // gentle pacing
    }
    if (anyEnriched) {
      _cache = null;
      await load(forceRefresh: true);
    }
  }

  Future<void> _enrichWord({required String id, required String word}) async {
    if (await _writeEnrichment(id: id, word: word)) {
      _cache = null;
      await load(forceRefresh: true);
    }
  }

  /// Fetches enrichment for [word] and writes it to the row. Returns true if a
  /// row update was issued (so callers can decide whether to reload). Does not
  /// touch the cache or reload — that's the caller's call.
  Future<bool> _writeEnrichment(
      {required String id, required String word}) async {
    try {
      final ai = _ref.read(geminiServiceProvider);
      final enriched = await ai.enrichWord(word);
      if (enriched == null) return false;
      if (enriched.ipa == null && enriched.example == null) return false;
      await _db.from('words').update({
        if (enriched.ipa != null) 'ipa': enriched.ipa,
        if (enriched.example != null) 'example_sentence': enriched.example,
      }).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reviewWord(Word word, int quality) async {
    final updatedWord = word.reviewed(quality);
    try {
      await _db.from('words').update({
        'ease_factor': updatedWord.easeFactor,
        'interval_days': updatedWord.intervalDays,
        'repetitions': updatedWord.repetitions,
        'next_review': updatedWord.nextReview.toIso8601String().split('T')[0],
      }).eq('id', word.id);

      // Update cache; _cache yoksa mevcut state'i ezme ([] ile silme riski).
      final current = _cache ?? state.value;
      if (current != null) {
        final next = [...current];
        final index = next.indexWhere((w) => w.id == word.id);
        if (index != -1) next[index] = updatedWord;
        _cache = next;
        state = AsyncValue.data(next);
        _scheduleDailyReminderFor(next);
      }
    } catch (e) {
      // Best-effort
    }
  }

  /// Atomically commit every quality rating from a review session.
  /// Each entry is `(wordId, quality)`. Uses one round-trip per word; we keep
  /// updates rather than upsert because a single batch upsert against
  /// auth-scoped RLS would require us to re-insert the full row.
  Future<void> commitReviewBatch(
      List<({String wordId, int quality})> results) async {
    if (results.isEmpty) return;
    final words = state.value ?? [];

    // Tek round-trip: tüm review güncellemeleri tek RPC ile commit edilir
    // (eskiden kelime başına ayrı UPDATE atılıyordu).
    final payload = <Map<String, dynamic>>[];
    for (final r in results) {
      final w = words.where((x) => x.id == r.wordId).firstOrNull;
      if (w == null) continue;
      final updated = w.reviewed(r.quality);
      payload.add({
        'id': r.wordId,
        'ease_factor': updated.easeFactor,
        'interval_days': updated.intervalDays,
        'repetitions': updated.repetitions,
        'next_review': updated.nextReview.toIso8601String().split('T')[0],
      });
      // Schedule per-word reminder fire-and-forget; not awaited to keep latency low.
      _scheduleNextReviewNotification(updated);
    }

    if (payload.isNotEmpty) {
      await _db.rpc('commit_word_reviews', params: {'p_reviews': payload});
    }

    // Aggregate XP into a single RPC call — quality-weighted per CLAUDE.md.
    final aggregateXp = results.fold<int>(0, (acc, r) {
      if (r.quality == 5) return acc + 20;
      if (r.quality == 4) return acc + 10;
      return acc + 5;
    });
    final avgQuality =
        results.fold<int>(0, (a, r) => a + r.quality) / results.length;
    try {
      final tzo = DateTime.now().timeZoneOffset.inHours;
      final sign = tzo >= 0 ? '+' : '-';
      final tzStr = '$sign${tzo.abs().toString().padLeft(2, '0')}:00';
      await _db.rpc('log_practice_session', params: {
        'p_mode': 'word_review_batch',
        'p_words_practiced': results.length,
        'p_avg_score': avgQuality,
        'p_xp_earned': aggregateXp,
        'p_timezone_offset': tzStr,
      });
      // XP/streak değişti — profil cache'ini düşür ki dashboard HUD güncellensin.
      await bustProfileCache();
      _ref.invalidate(profileProvider);
    } catch (_) {
      // XP is best-effort.
    }

    _cache = null;
    await load(forceRefresh: true);
  }

  Future<void> _scheduleNextReviewNotification(Word updated) async {
    try {
      final notificationId = updated.id.hashCode;
      await NotificationService().scheduleReviewReminder(
        notificationId,
        'Hatırlatma Zamanı!',
        '"${updated.word}" kelimesinin tekrar zamanı geldi!',
        updated.nextReview,
      );
    } catch (_) {
      // Notifications are best-effort.
    }
  }

  Future<void> deleteWord(String wordId) async {
    await _db.from('words').delete().eq('id', wordId);
    // Lokal listeden düş — tek silme için tüm tabloyu yeniden çekme.
    final current = _cache ?? state.value;
    if (current != null) {
      _cache = current.where((w) => w.id != wordId).toList();
      state = AsyncValue.data(_cache!);
      unawaited(_ref.read(wordsCacheProvider).putAll(_cache!));
    } else {
      await load(forceRefresh: true);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
