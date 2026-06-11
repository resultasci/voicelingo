import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// İlerleme analizi için Supabase view + RPC repository.
class ActivityService {
  ActivityService(this._db);
  final SupabaseClient _db;

  /// Son [days] günün günlük XP toplamı. day -> xp map.
  Future<Map<DateTime, int>> getDailyXp({int days = 90}) async {
    try {
      final raw = await _db.rpc('get_daily_xp_range', params: {'p_days': days});
      if (raw is! List) return const {};
      final out = <DateTime, int>{};
      for (final row in raw) {
        if (row is! Map) continue;
        final dayStr = row['day']?.toString();
        if (dayStr == null) continue;
        final d = DateTime.tryParse(dayStr);
        final xp = (row['xp'] as num?)?.toInt() ?? 0;
        if (d != null) out[DateTime(d.year, d.month, d.day)] = xp;
      }
      return out;
    } catch (_) {
      // best-effort: heatmap boş kalır, dashboard çalışmaya devam eder
      return const {};
    }
  }

  /// Mastery özeti: words/grammar/lessons total + mastered sayıları.
  Future<MasterySummary?> getMasterySummary() async {
    try {
      final res = await _db.rpc('get_mastery_summary');
      if (res is! Map<String, dynamic>) return null;
      if (res['ok'] != true) return null;
      return MasterySummary.fromMap(res);
    } catch (_) {
      // best-effort: kart "veri yok" durumuna düşer
      return null;
    }
  }

  /// Son 30 gündeki en sık [limit] gramer hatası.
  Future<List<TopError>> getTopErrors({int limit = 5}) async {
    try {
      final raw = await _db.rpc('get_top_errors', params: {'p_limit': limit});
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => TopError.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // best-effort: liste boş görünür
      return const [];
    }
  }
}

class MasterySummary {
  final int wordsTotal;
  final int wordsMastered;
  final int grammarTotal;
  final int grammarCompleted;
  final int grammarMastered;
  final int lessonsTotal;
  final int lessonsCompleted;
  final int lessonsMastered;

  const MasterySummary({
    required this.wordsTotal,
    required this.wordsMastered,
    required this.grammarTotal,
    required this.grammarCompleted,
    required this.grammarMastered,
    required this.lessonsTotal,
    required this.lessonsCompleted,
    required this.lessonsMastered,
  });

  double get wordsRatio => wordsTotal == 0 ? 0 : wordsMastered / wordsTotal;
  double get grammarRatio =>
      grammarTotal == 0 ? 0 : grammarCompleted / grammarTotal;
  double get lessonsRatio =>
      lessonsTotal == 0 ? 0 : lessonsCompleted / lessonsTotal;

  factory MasterySummary.fromMap(Map<String, dynamic> m) {
    final w = (m['words'] as Map?)?.cast<String, dynamic>() ?? const {};
    final g = (m['grammar'] as Map?)?.cast<String, dynamic>() ?? const {};
    final l = (m['lessons'] as Map?)?.cast<String, dynamic>() ?? const {};
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    return MasterySummary(
      wordsTotal: i(w['total']),
      wordsMastered: i(w['mastered']),
      grammarTotal: i(g['total']),
      grammarCompleted: i(g['completed']),
      grammarMastered: i(g['mastered']),
      lessonsTotal: i(l['total']),
      lessonsCompleted: i(l['completed']),
      lessonsMastered: i(l['mastered']),
    );
  }
}

class TopError {
  final String type;
  final int occurrences;
  const TopError({required this.type, required this.occurrences});

  factory TopError.fromMap(Map<String, dynamic> m) => TopError(
        type: m['error_type']?.toString() ?? '',
        occurrences: (m['occurrences'] as num?)?.toInt() ?? 0,
      );
}

// =============================================================================
// Providers
// =============================================================================
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService(Supabase.instance.client);
});

final dailyXpProvider =
    FutureProvider.autoDispose.family<Map<DateTime, int>, int>(
  (ref, days) async {
    return ref.watch(activityServiceProvider).getDailyXp(days: days);
  },
);

final masterySummaryProvider =
    FutureProvider.autoDispose<MasterySummary?>((ref) async {
  return ref.watch(activityServiceProvider).getMasterySummary();
});

final topErrorsProvider =
    FutureProvider.autoDispose<List<TopError>>((ref) async {
  return ref.watch(activityServiceProvider).getTopErrors();
});
