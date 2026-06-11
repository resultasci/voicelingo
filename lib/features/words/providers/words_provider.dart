import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// AppException hierarchy defines our own AuthException; hide Supabase's to avoid
// the ambiguous-import clash (AuthState etc. still come from Supabase).
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/ai/gemini_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/models/word.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/offline/words_cache.dart';
import '../../../core/services/notification_service.dart';
import '../../gamification/models/daily_quest.dart';
import '../../gamification/providers/gamification_providers.dart';
import '../../profile/providers/profile_provider.dart';
import '../services/words_repository.dart';

// Tüketiciler DuplicateWordException'ı tarihsel olarak buradan import eder.
export '../services/words_repository.dart' show DuplicateWordException;

final wordsProvider =
    StateNotifierProvider<WordsNotifier, AsyncValue<List<Word>>>(
  (ref) => WordsNotifier(ref),
);

/// Dashboard projeksiyonları. Sayı provider'ları int eşitliği sayesinde
/// kelime listesindeki alakasız mutasyonlarda (enrichment yazımı, yeniden
/// sıralama) izleyen widget'ları rebuild etmez; vadesi gelen listenin kendisi
/// yalnız tap anında `ref.read(dueWordsProvider)` ile alınmalıdır.
final dueWordsProvider = Provider.autoDispose<List<Word>>((ref) {
  final words = ref.watch(wordsProvider).value ?? const <Word>[];
  return words.where((w) => w.isDue).toList();
});

final dueWordsCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(dueWordsProvider).length,
);

final wordsCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(wordsProvider).value?.length ?? 0,
);

class WordsNotifier extends StateNotifier<AsyncValue<List<Word>>> {
  WordsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
    // Hesap değişiminde (signIn/signOut) bellekteki liste önceki kullanıcıya
    // ait kalmasın — provider global olduğu için autoDispose ile çözülmüyor.
    _authSub = _repo.authStateChanges.listen((change) {
      final event = change.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut) {
        _cache = null;
        load(forceRefresh: true);
      }
    });
  }

  final Ref _ref;
  late final WordsRepository _repo = _ref.read(wordsRepositoryProvider);
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
      final userId = _repo.currentUserId;
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

      final words = await _repo.fetchAll(userId);

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

  /// Daily quest progress'ini best-effort artırır. Quest tamamlandıysa XP
  /// server'da yazılmıştır — profil cache'i düşürülür ki HUD güncellensin.
  Future<void> _bumpQuest(QuestType type, int delta) async {
    try {
      final svc = _ref.read(dailyQuestsServiceProvider);
      final updated = await svc.incrementByType(type, delta: delta);
      if (updated == null) return;
      _ref.invalidate(dailyQuestsProvider);
      if (updated.isCompleted) {
        await bustProfileCache();
        _ref.invalidate(profileProvider);
      }
    } catch (_) {
      // Quests are best-effort.
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
    _ref
        .read(notificationServiceProvider)
        .scheduleDailyReviewReminder(dueCount);
  }

  Future<void> addWord(String word, String translation) async {
    final userId = _repo.currentUserId;
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
      final newWord = await _repo.insertWord(
        userId: userId,
        word: trimmedWord,
        translation: translation.trim(),
      );

      // Insert zaten yeni satırı döndürüyor — tüm tabloyu yeniden çekmek yerine
      // listenin başına ekle (created_at desc sıralamasıyla uyumlu).
      _cache = [newWord, ...(_cache ?? state.value ?? const <Word>[])];
      state = AsyncValue.data(_cache!);
      unawaited(_ref.read(wordsCacheProvider).putAll(_cache!));
      AppLogger.info('Yeni kelime başarıyla eklendi: $trimmedWord',
          tag: 'WordsProvider');

      // Fire-and-forget enrichment: never block the user.
      unawaited(_enrichWord(id: newWord.id, word: trimmedWord));
      unawaited(_bumpQuest(QuestType.learnWords, 1));
    } on DuplicateWordException {
      AppLogger.warning(
          'Postgres veritabanında kelime zaten mevcut (Unique Constraint).',
          tag: 'WordsProvider');
      rethrow;
    } catch (e, st) {
      AppLogger.error('Kelime eklenirken hata oluştu', e, st);
      rethrow;
    }
  }

  /// Generates topic-based words via Gemini, inserts the de-duplicated set, then
  /// enriches a bounded subset (IPA + example). Returns how many words were
  /// actually inserted (after local + server-side dedup). May throw
  /// [AiException] (e.g. 429 daily limit) from the generation call — callers
  /// should catch and surface its localized message.
  Future<int> generateAndAddWords(String topic, int count) async {
    final userId = _repo.currentUserId;
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
    final inserted = await _repo.insertBatch([
      for (final g in fresh) (word: g.en.trim(), translation: g.tr.trim()),
    ]);

    _cache = null;
    await load(forceRefresh: true);

    // Enrich a bounded subset to stay well under the daily enrich cap (100/day).
    unawaited(_enrichBatch(inserted));
    unawaited(_bumpQuest(QuestType.learnWords, inserted.length));
    return inserted.length;
  }

  Future<void> _enrichBatch(List<({String id, String word})> items) async {
    const maxEnrich = 10;
    const chunkSize = 3;
    final queue = items.take(maxEnrich).toList();
    var anyEnriched = false;
    for (var i = 0; i < queue.length; i += chunkSize) {
      // Update each word's DB row in place but DON'T reload per chunk — reloading
      // back-to-back flickers the list to a spinner and wastes round-trips.
      final results = await Future.wait([
        for (final it in queue.skip(i).take(chunkSize))
          _writeEnrichment(id: it.id, word: it.word),
      ]);
      anyEnriched = results.any((r) => r) || anyEnriched;
      if (i + chunkSize < queue.length) {
        await Future.delayed(
            const Duration(milliseconds: 500)); // gentle pacing
      }
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
      await _repo.updateEnrichment(
        id: id,
        ipa: enriched.ipa,
        example: enriched.example,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reviewWord(Word word, int quality) async {
    final updatedWord = word.reviewed(quality);
    try {
      await _repo.updateReview(updatedWord);

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
      unawaited(_scheduleNextReviewNotification(updated));
    }

    await _repo.commitReviews(payload);

    // Aggregate XP into a single RPC call — quality-weighted per CLAUDE.md.
    final aggregateXp = results.fold<int>(0, (acc, r) {
      if (r.quality == 5) return acc + 20;
      if (r.quality == 4) return acc + 10;
      return acc + 5;
    });
    final avgQuality =
        results.fold<int>(0, (a, r) => a + r.quality) / results.length;
    try {
      await _repo.logPracticeSession(
        mode: 'word_review_batch',
        wordsPracticed: results.length,
        avgScore: avgQuality,
        xpEarned: aggregateXp,
      );
      // XP/streak değişti — profil cache'ini düşür ki dashboard HUD güncellensin.
      await bustProfileCache();
      _ref.invalidate(profileProvider);
    } catch (_) {
      // XP is best-effort.
    }
    unawaited(_bumpQuest(QuestType.reviewWords, results.length));

    _cache = null;
    await load(forceRefresh: true);
  }

  Future<void> _scheduleNextReviewNotification(Word updated) async {
    try {
      final notificationId = updated.id.hashCode;
      await _ref.read(notificationServiceProvider).scheduleReviewReminder(
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
    await _repo.delete(wordId);
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
