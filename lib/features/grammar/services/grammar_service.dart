import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../providers/profile_provider.dart';
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

  /// Kullanıcının tüm konulara ait progress'i (topic_id → progress map).
  Future<Map<String, GrammarProgress>> listProgress() async {
    final user = _db.auth.currentUser;
    if (user == null) return const {};
    final data =
        await _db.from('user_grammar_progress').select().eq('user_id', user.id);
    final result = <String, GrammarProgress>{};
    for (final row in (data as List)) {
      final p = GrammarProgress.fromMap(row as Map<String, dynamic>);
      result[p.topicId] = p;
    }
    return result;
  }

  /// Quiz tamamlandığında çağrılır. Score 0-100 arası; >=70 → completed,
  /// >=95 → mastered.
  Future<GrammarProgress> recordQuizResult({
    required String topicId,
    required int score,
    required int xpReward,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw StateError('Oturum yok.');
    }

    final newStatus = score >= 95
        ? GrammarStatus.mastered
        : score >= 70
            ? GrammarStatus.completed
            : GrammarStatus.inProgress;

    // Upsert. attempts'i +1 yapan SQL atomic değil ama best-effort yeterli;
    // double tap durumunda 1-2 attempt sapması kabul edilebilir.
    final existing = await _db
        .from('user_grammar_progress')
        .select('attempts, quiz_score')
        .eq('user_id', user.id)
        .eq('topic_id', topicId)
        .maybeSingle();

    final prevAttempts = (existing?['attempts'] as num?)?.toInt() ?? 0;
    final prevScore = (existing?['quiz_score'] as num?)?.toInt() ?? 0;
    final bestScore = score > prevScore ? score : prevScore;

    final row = await _db
        .from('user_grammar_progress')
        .upsert({
          'user_id': user.id,
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

    // Tamamlandıysa XP ödülü. Mastered'da XP zaten completed turunda verildi
    // sayılır (idempotent: yalnız ilk completed'da XP verilir).
    if (newStatus == GrammarStatus.completed &&
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
