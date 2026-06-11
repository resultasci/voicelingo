import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../models/grammar_topic.dart';

/// Gramer konuları + kullanıcı progress'i için Supabase repository.
class GrammarService {
  GrammarService(this._db);
  final SupabaseClient _db;

  /// Tüm konular, level + order_index ile sıralı.
  Future<List<GrammarTopic>> listAllTopics() async {
    return CachedRepository.getOrFetch<List<GrammarTopic>>(
      box: Hive.box<Map>(HiveBoxes.grammarTopics),
      key: 'all_topics',
      fromJson: (m) => (m['list'] as List)
          .map((e) => GrammarTopic.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      toJson: (L) => {'list': L.map((e) => e.toMap()).toList()},
      fetchRemote: () async {
        final data = await _db
            .from('grammar_topics')
            .select()
            .order('level')
            .order('order_index');
        return (data as List)
            .map((e) => GrammarTopic.fromMap(e as Map<String, dynamic>))
            .toList();
      },
      // Gramer konuları çok nadir değişir, 7 günlük cache ideal.
      maxAge: const Duration(days: 7),
    );
  }

  /// Konuyu `code` ile getirir (lesson runner içerikteki `topic_code`'u
  /// resolve etmek için). Bulunamazsa null.
  Future<GrammarTopic?> getTopicByCode(String code) async {
    final row = await _db
        .from('grammar_topics')
        .select()
        .eq('code', code)
        .maybeSingle();
    if (row == null) return null;
    return GrammarTopic.fromMap(row);
  }

  static String _progressKey(String userId) => 'grammar_progress_$userId';

  /// Kullanıcının tüm konulara ait progress'i (topic_id → progress map).
  /// SWR cache'li (30dk TTL); yazma noktası [recordQuizResult] girdiyi düşürür.
  Future<Map<String, GrammarProgress>> listProgress() async {
    final user = _db.auth.currentUser;
    if (user == null) return const {};
    return CachedRepository.getOrFetch<Map<String, GrammarProgress>>(
      box: Hive.box<Map>(HiveBoxes.progress),
      key: _progressKey(user.id),
      fromJson: (m) {
        final result = <String, GrammarProgress>{};
        for (final e in (m['list'] as List? ?? const [])) {
          final p =
              GrammarProgress.fromMap(Map<String, dynamic>.from(e as Map));
          result[p.topicId] = p;
        }
        return result;
      },
      toJson: (map) => {'list': map.values.map((p) => p.toMap()).toList()},
      maxAge: const Duration(minutes: 30),
      fetchRemote: () async {
        final data = await _db
            .from('user_grammar_progress')
            .select()
            .eq('user_id', user.id);
        final result = <String, GrammarProgress>{};
        for (final row in (data as List)) {
          final p = GrammarProgress.fromMap(row as Map<String, dynamic>);
          result[p.topicId] = p;
        }
        return result;
      },
    );
  }

  /// Progress cache girdisini düşürür — pull-to-refresh ve yazma sonrası
  /// `ref.invalidate(grammarProgressProvider)` ÖNCESİNDE çağrılmalı.
  Future<void> invalidateProgressCache() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await CachedRepository.invalidate(
        Hive.box<Map>(HiveBoxes.progress), _progressKey(user.id));
  }

  /// Quiz tamamlandığında çağrılır. Score 0-100; rubrik [deriveGrammarStatus].
  ///
  /// Hızlı yol: record_grammar_quiz RPC'si select+upsert+XP'yi tek
  /// round-trip'te ve atomik işler. Migration henüz canlıda değilse
  /// (function-missing) eski 3-round-trip yola düşülür — davranış birebir.
  Future<GrammarProgress> recordQuizResult({
    required String topicId,
    required int score,
    required int xpReward,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw StateError('Oturum yok.');
    }

    try {
      final res = await _db.rpc('record_grammar_quiz', params: {
        'p_topic_id': topicId,
        'p_score': score,
        'p_xp_reward': xpReward,
      });
      if (res is Map) {
        final m = Map<String, dynamic>.from(res);
        final progress = GrammarProgress.fromMap(
            Map<String, dynamic>.from(m['progress'] as Map));
        await invalidateProgressCache();
        if (((m['xp_awarded'] as num?)?.toInt() ?? 0) > 0) {
          // XP değişti — eski profil Hive'dan servis edilmesin.
          await bustProfileCache();
        }
        return progress;
      }
      // Beklenmedik şekil — legacy yol denesin.
    } on PostgrestException catch (e) {
      // Yalnız function-missing'de fallback; diğer DB hataları aynen fırlar
      // (merkezi error_handler map'ler).
      if (!_isFunctionMissing(e)) rethrow;
    }
    return _recordQuizResultLegacy(
        userId: user.id, topicId: topicId, score: score, xpReward: xpReward);
  }

  /// PGRST202: PostgREST schema cache'inde function yok; 42883: Postgres
  /// undefined_function.
  static bool _isFunctionMissing(PostgrestException e) =>
      e.code == 'PGRST202' || e.code == '42883';

  /// Eski 3-round-trip akış — record_grammar_quiz migrate edilene kadar
  /// güvenlik ağı. RPC canlıda doğrulanınca kaldırılabilir.
  Future<GrammarProgress> _recordQuizResultLegacy({
    required String userId,
    required String topicId,
    required int score,
    required int xpReward,
  }) async {
    final newStatus = deriveGrammarStatus(score);

    // Upsert. attempts'i +1 yapan SQL atomic değil ama best-effort yeterli;
    // double tap durumunda 1-2 attempt sapması kabul edilebilir.
    final existing = await _db
        .from('user_grammar_progress')
        .select('attempts, quiz_score')
        .eq('user_id', userId)
        .eq('topic_id', topicId)
        .maybeSingle();

    final prevAttempts = (existing?['attempts'] as num?)?.toInt() ?? 0;
    final prevScore = (existing?['quiz_score'] as num?)?.toInt() ?? 0;
    final bestScore = score > prevScore ? score : prevScore;

    final row = await _db
        .from('user_grammar_progress')
        .upsert({
          'user_id': userId,
          'topic_id': topicId,
          'status': newStatus.code,
          'quiz_score': bestScore,
          'attempts': prevAttempts + 1,
          'completed_at': newStatus == GrammarStatus.completed ||
                  newStatus == GrammarStatus.mastered
              ? DateTime.now().toUtc().toIso8601String()
              : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    // Progress değişti — cache girdisi düşmezse provider invalidate'i bayat
    // satırı yeniden servis eder (XP dalından bağımsız her yazımda).
    await invalidateProgressCache();

    // Best score ilk kez 70 eşiğini geçtiyse XP (doğrudan mastered'a atlama
    // dahil — RPC ile aynı kural; eski kod ≥95 ilk denemede XP'yi atlıyordu).
    if ((newStatus == GrammarStatus.completed ||
            newStatus == GrammarStatus.mastered) &&
        prevScore < 70 &&
        xpReward > 0) {
      try {
        await _db.rpc('add_xp', params: {'p_amount': xpReward});
        // XP değişti — eski profil Hive'dan servis edilmesin.
        await bustProfileCache();
      } catch (_) {
        // Eski schema'da add_xp olmayabilir — best effort.
      }
    }

    return GrammarProgress.fromMap(row);
  }
}

final grammarServiceProvider = Provider<GrammarService>((ref) {
  return GrammarService(Supabase.instance.client);
});

// =============================================================================
// Reactive providers
// =============================================================================

/// Tüm konular (statik). Faz 6+ A1 seed, sonraki fazlar A2-C2 ekler.
final grammarTopicsProvider = FutureProvider<List<GrammarTopic>>((ref) async {
  final svc = ref.watch(grammarServiceProvider);
  return svc.listAllTopics();
});

/// Kullanıcı progress map'i. Quiz tamamlandığında invalidate edilir.
final grammarProgressProvider =
    FutureProvider.autoDispose<Map<String, GrammarProgress>>((ref) async {
  final svc = ref.watch(grammarServiceProvider);
  return svc.listProgress();
});
