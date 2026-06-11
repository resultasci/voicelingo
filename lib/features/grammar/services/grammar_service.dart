import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
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
  /// record_grammar_quiz RPC'si select+upsert+XP'yi tek round-trip'te ve
  /// atomik işler; idempotent XP (best score ilk kez 70 eşiğini geçince bir
  /// kez). DB hataları aynen fırlar — merkezi error_handler map'ler.
  Future<GrammarProgress> recordQuizResult({
    required String topicId,
    required int score,
    required int xpReward,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw StateError('Oturum yok.');
    }

    final res = await _db.rpc('record_grammar_quiz', params: {
      'p_topic_id': topicId,
      'p_score': score,
      'p_xp_reward': xpReward,
    });
    if (res is! Map) {
      throw const NetworkException(
          'record_grammar_quiz beklenmeyen cevap döndürdü.');
    }
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
