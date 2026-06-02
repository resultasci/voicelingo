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

const _starterWords = [
  ('apple', 'elma'),
  ('book', 'kitap'),
  ('water', 'su'),
  ('house', 'ev'),
  ('car', 'araba'),
  ('phone', 'telefon'),
  ('food', 'yemek'),
  ('time', 'zaman'),
  ('friend', 'arkadaş'),
  ('school', 'okul'),
  ('work', 'iş'),
  ('day', 'gün'),
  ('night', 'gece'),
  ('city', 'şehir'),
  ('country', 'ülke'),
  ('money', 'para'),
  ('help', 'yardım'),
  ('love', 'sevgi'),
  ('music', 'müzik'),
  ('sport', 'spor'),
  ('computer', 'bilgisayar'),
  ('family', 'aile'),
  ('health', 'sağlık'),
  ('weather', 'hava durumu'),
  ('travel', 'seyahat'),
  ('coffee', 'kahve'),
  ('language', 'dil'),
  ('study', 'çalışmak'),
  ('happy', 'mutlu'),
  ('success', 'başarı'),
];

class WordsNotifier extends StateNotifier<AsyncValue<List<Word>>> {
  WordsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final _db = Supabase.instance.client;
  List<Word>? _cache;

  Future<void> load({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cache != null) {
        state = AsyncValue.data(_cache!);
        return;
      }
      state = const AsyncValue.loading();
      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        _cache = const [];
        state = const AsyncValue.data([]);
        return;
      }

      // Offline ise Hive cache'ten oku — kullanıcı yenileme bekleyince empty
      // göstermek yerine bilinen state'i göster.
      final connectivity = _ref.read(connectivityServiceProvider);
      final online = await connectivity.isOnline();
      final wordsCache = _ref.read(wordsCacheProvider);
      if (!online) {
        final cached = wordsCache.readAll();
        _cache = cached;
        state = AsyncValue.data(cached);
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

      // Seed only on the very first launch. profileProvider already fetched
      // `seeded_at`; read from there to avoid a second round-trip.
      if (words.isEmpty) {
        final profile = await _ref.read(profileProvider.future);
        if (profile != null && profile.seededAt == null) {
          await _insertStarterWords(userId);
          await _markSeeded(userId);
          await load(forceRefresh: true);
          return;
        }
      }

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

  Future<void> _markSeeded(String userId) async {
    try {
      await _db
          .from('profiles')
          .update({'seeded_at': DateTime.now().toUtc().toIso8601String()}).eq(
              'id', userId);
    } catch (_) {
      // If this fails the user just risks a one-time re-seed; non-critical.
    }
  }

  Future<void> _insertStarterWords(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = _starterWords
        .map((pair) => {
              'user_id': userId,
              'word': pair.$1,
              'translation': pair.$2,
              'next_review': today,
            })
        .toList();
    await _db.from('words').insert(rows);
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

      _cache = null;
      await load(forceRefresh: true);
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

  Future<void> _enrichWord({required String id, required String word}) async {
    try {
      final ai = _ref.read(geminiServiceProvider);
      final enriched = await ai.enrichWord(word);
      if (enriched == null) return;
      await _db.from('words').update({
        if (enriched.ipa != null) 'ipa': enriched.ipa,
        if (enriched.example != null) 'example_sentence': enriched.example,
      }).eq('id', id);
      _cache = null;
      await load(forceRefresh: true);
    } catch (_) {}
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

      // Update cache
      if (_cache != null) {
        final index = _cache!.indexWhere((w) => w.id == word.id);
        if (index != -1) {
          _cache![index] = updatedWord;
        }
      }
      state = AsyncValue.data(_cache ?? []);
      _scheduleDailyReminderFor(_cache ?? []);
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

    final updates = <Future<void>>[];
    for (final r in results) {
      final w = words.where((x) => x.id == r.wordId).firstOrNull;
      if (w == null) continue;
      final updated = w.reviewed(r.quality);
      updates.add(_db.from('words').update({
        'ease_factor': updated.easeFactor,
        'interval_days': updated.intervalDays,
        'repetitions': updated.repetitions,
        'next_review': updated.nextReview.toIso8601String().split('T')[0],
      }).eq('id', r.wordId));
      // Schedule per-word reminder fire-and-forget; not awaited to keep latency low.
      _scheduleNextReviewNotification(updated);
    }

    await Future.wait(updates);

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
    _cache = null;
    await load(forceRefresh: true);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
