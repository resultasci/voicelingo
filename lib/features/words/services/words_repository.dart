import 'package:flutter_riverpod/flutter_riverpod.dart';
// AppException hiyerarşisi kendi AuthException'ını tanımlar; Supabase'inkini
// gizle ki aynı isimli iki sınıf karışmasın.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/models/word.dart';

/// [WordsRepository.insertWord] kelime/lang/user unique index'ine takılınca
/// fırlatılır. Çağıranlar yakalayıp lokalize mesaj göstermeli — asla Sentry'ye
/// taşınmaz.
class DuplicateWordException extends AppException {
  final String word;
  DuplicateWordException(this.word)
      : super('Kelime zaten ekli: $word', code: 'duplicate_word');
}

/// Kelime verisinin tek Supabase erişim noktası. `WordsNotifier` orkestrasyonu
/// (SWR cache, dedup, quest/bildirim yan etkileri) yapar; SQL/RPC çağrıları
/// burada yaşar ki notifier testlerde sahte repository ile çalışabilsin.
class WordsRepository {
  WordsRepository(this._db);
  final SupabaseClient _db;

  String? get currentUserId => _db.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  Future<List<Word>> fetchAll(String userId) async {
    final data = await _db
        .from('words')
        .select(
            'id,user_id,word,translation,ease_factor,interval_days,repetitions,next_review,created_at,ipa,example_sentence')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Word.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Tek kelime ekler; eklenen satırı döner. Unique index ihlalini (23505)
  /// sınırda [DuplicateWordException]'a çevirir.
  Future<Word> insertWord({
    required String userId,
    required String word,
    required String translation,
  }) async {
    try {
      final inserted = await _db
          .from('words')
          .insert({
            'user_id': userId,
            'word': word,
            'translation': translation,
            'next_review': DateTime.now().toIso8601String().split('T')[0],
          })
          .select()
          .single();
      return Word.fromMap(inserted);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw DuplicateWordException(word);
      rethrow;
    }
  }

  /// Toplu insert (`add_words_batch` RPC, ON CONFLICT DO NOTHING). Yalnız
  /// gerçekten eklenen satırların (id, word) çiftini döner.
  Future<List<({String id, String word})>> insertBatch(
      List<({String word, String translation})> words) async {
    final rows = await _db.rpc('add_words_batch', params: {
      'p_words': [
        for (final w in words) {'word': w.word, 'translation': w.translation},
      ],
    });
    return (rows as List)
        .whereType<Map>()
        .map((r) => (id: r['id'] as String, word: r['word'] as String))
        .toList();
  }

  Future<void> updateEnrichment({
    required String id,
    String? ipa,
    String? example,
  }) async {
    await _db.from('words').update({
      if (ipa != null) 'ipa': ipa,
      if (example != null) 'example_sentence': example,
    }).eq('id', id);
  }

  /// Tek kelimenin SM-2 alanlarını günceller.
  Future<void> updateReview(Word updated) async {
    await _db.from('words').update({
      'ease_factor': updated.easeFactor,
      'interval_days': updated.intervalDays,
      'repetitions': updated.repetitions,
      'next_review': updated.nextReview.toIso8601String().split('T')[0],
    }).eq('id', updated.id);
  }

  /// Review oturumunun tüm güncellemelerini tek RPC ile commit eder
  /// (`commit_word_reviews`).
  Future<void> commitReviews(List<Map<String, dynamic>> payload) async {
    if (payload.isEmpty) return;
    await _db.rpc('commit_word_reviews', params: {'p_reviews': payload});
  }

  /// XP/streak kaydı (`log_practice_session` RPC).
  Future<void> logPracticeSession({
    required String mode,
    required int wordsPracticed,
    required double avgScore,
    required int xpEarned,
  }) async {
    final tzo = DateTime.now().timeZoneOffset.inHours;
    final sign = tzo >= 0 ? '+' : '-';
    final tzStr = '$sign${tzo.abs().toString().padLeft(2, '0')}:00';
    await _db.rpc('log_practice_session', params: {
      'p_mode': mode,
      'p_words_practiced': wordsPracticed,
      'p_avg_score': avgScore,
      'p_xp_earned': xpEarned,
      'p_timezone_offset': tzStr,
    });
  }

  Future<void> delete(String wordId) async {
    await _db.from('words').delete().eq('id', wordId);
  }
}

final wordsRepositoryProvider = Provider<WordsRepository>(
  (ref) => WordsRepository(Supabase.instance.client),
);
