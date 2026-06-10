import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_quest.dart';

/// Daily quest CRUD + günlük generation logic.
///
/// İlk açılışta veya gün değişiminde [ensureToday] çağrılır — bugün için
/// görev yoksa 3 quest üretip insert eder.
class DailyQuestsService {
  DailyQuestsService(this._db);
  final SupabaseClient _db;

  /// Bugüne ait quest'leri döner (3 adet). Yoksa generate edip insert eder.
  Future<List<DailyQuest>> ensureToday() async {
    final user = _db.auth.currentUser;
    if (user == null) return const [];

    final today = _today();
    final existing = await _db
        .from('daily_quests')
        .select()
        .eq('user_id', user.id)
        .eq('quest_date', today.toIso8601String().split('T').first);

    if (existing.isNotEmpty) {
      return existing.map((e) => DailyQuest.fromMap(e)).toList();
    }

    // Generate: rastgele 3 quest tipi seç, target/XP makul aralıkta
    final generated = _generate(userId: user.id, date: today);
    final inserted = await _db
        .from('daily_quests')
        .insert(generated.map((q) => _toInsertMap(q)).toList())
        .select();

    return (inserted as List)
        .map((e) => DailyQuest.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Bir quest'in progress'ini günceller; target'a ulaşılırsa completed_at set
  /// edilir. XP ödülü RPC üzerinden ayrı verilir (atomik).
  Future<DailyQuest?> updateProgress({
    required String questId,
    required int delta,
  }) async {
    final res = await _db.rpc('increment_quest_progress', params: {
      'p_quest_id': questId,
      'p_delta': delta,
    });
    if (res is! Map<String, dynamic>) return null;
    if (res['ok'] != true) return null;
    final row = res['row'] as Map<String, dynamic>?;
    if (row == null) return null;
    return DailyQuest.fromMap(row);
  }

  /// Bugünün tamamlanmamış [type] quest'inin progress'ini artırır; o tipte
  /// aktif quest yoksa no-op. Güncellenen quest'i döner (tamamlanma kontrolü
  /// için), bulunamazsa null.
  Future<DailyQuest?> incrementByType(QuestType type, {int delta = 1}) async {
    final user = _db.auth.currentUser;
    if (user == null || delta <= 0) return null;
    final rows = await _db
        .from('daily_quests')
        .select('id')
        .eq('user_id', user.id)
        .eq('quest_date', _today().toIso8601String().split('T').first)
        .eq('quest_type', type.code)
        .isFilter('completed_at', null)
        .limit(1);
    if (rows.isEmpty) return null;
    return updateProgress(questId: rows.first['id'] as String, delta: delta);
  }

  List<DailyQuest> _generate({required String userId, required DateTime date}) {
    final rng = Random(date.day * 31 + date.month);
    // practiceMinutes üretim havuzunda değil: uygulamada süre ölçümü olmadığı
    // için bu tip asla tamamlanamıyor. Enum değeri eski satırlar için duruyor.
    final types = QuestType.values
        .where((t) => t != QuestType.practiceMinutes)
        .toList()
      ..shuffle(rng);
    final chosen = types.take(3).toList();
    return chosen.map((t) {
      final target = switch (t) {
        QuestType.learnWords => 3 + rng.nextInt(3), // 3-5 kelime
        QuestType.reviewWords => 5 + rng.nextInt(6), // 5-10 kelime
        QuestType.practiceMinutes => 5 + 5 * rng.nextInt(3), // 5/10/15 dk
        QuestType.conversationTurns => 5 + 5 * rng.nextInt(2), // 5 veya 10 tur
        QuestType.perfectScore => 1,
      };
      final xp = switch (t) {
        QuestType.perfectScore => 75,
        QuestType.conversationTurns => 60,
        QuestType.practiceMinutes => 50,
        _ => 40,
      };
      return DailyQuest(
        id: '',
        userId: userId,
        questDate: date,
        type: t,
        target: target,
        progress: 0,
        xpReward: xp,
      );
    }).toList();
  }

  Map<String, dynamic> _toInsertMap(DailyQuest q) => {
        'user_id': q.userId,
        'quest_date': q.questDate.toIso8601String().split('T').first,
        'quest_type': q.type.code,
        'target': q.target,
        'progress': q.progress,
        'xp_reward': q.xpReward,
      };

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
