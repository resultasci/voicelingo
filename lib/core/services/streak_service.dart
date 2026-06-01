import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';

/// Streak hesaplama + reset mantığı.
///
/// SQL hesaplaması yerine client-side yapıyoruz çünkü:
///   - Cron schedule güvenilmez (Supabase Edge Function cron'ları kullanıcı bağımsız)
///   - Streak reset her cold start'ta hesaplanırsa "tam zamanında" güncellenir
///   - Streak freeze tüketimi UI'da onay isteyebilir (her gün otomatik tüketmek istemiyoruz)
///
/// Algoritma (her app açılışında [reconcile] çağırılır):
///   1. `streakLastDate` bugün veya dün → streak korunur
///   2. `streakLastDate` 2 gün önce → 1 streak_freeze varsa harca, yoksa streak=0
///   3. `streakLastDate` 3+ gün önce → streak=0 (freeze yetmez)
///   4. `streakLastDate` null → streak=0
class StreakService {
  StreakService(this._db);
  final SupabaseClient _db;

  /// Cold start'ta çağrılır. Profile'ı oku, gerekirse streak'i sıfırla, return et.
  Future<StreakReconcileResult> reconcile() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      return const StreakReconcileResult(status: StreakStatus.noSession);
    }

    final row = await _db
        .from('profiles')
        .select('streak_days, streak_last_date, streak_freezes')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      return const StreakReconcileResult(status: StreakStatus.unchanged);
    }

    final streakDays = (row['streak_days'] as num?)?.toInt() ?? 0;
    final freezes = (row['streak_freezes'] as num?)?.toInt() ?? 0;
    final lastDateStr = row['streak_last_date'] as String?;
    final lastDate =
        lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;

    final decision = _classify(now: DateTime.now(), lastDate: lastDate);

    switch (decision) {
      case _StreakDecision.continuing:
      case _StreakDecision.todayAlready:
        return StreakReconcileResult(
          status: StreakStatus.unchanged,
          currentStreak: streakDays,
          freezes: freezes,
        );

      case _StreakDecision.consumeFreeze:
        if (freezes > 0) {
          await _db.from('profiles').update({
            'streak_freezes': freezes - 1,
            'streak_last_date': _today().toIso8601String(),
          }).eq('id', user.id);
          return StreakReconcileResult(
            status: StreakStatus.freezeUsed,
            currentStreak: streakDays,
            freezes: freezes - 1,
          );
        }
        // Freeze yok — reset
        await _resetStreak(user.id);
        return const StreakReconcileResult(
          status: StreakStatus.reset,
          currentStreak: 0,
          freezes: 0,
        );

      case _StreakDecision.tooFar:
        await _resetStreak(user.id);
        return StreakReconcileResult(
          status: StreakStatus.reset,
          currentStreak: 0,
          freezes: freezes,
        );

      case _StreakDecision.firstTime:
        return StreakReconcileResult(
          status: StreakStatus.unchanged,
          currentStreak: streakDays,
          freezes: freezes,
        );
    }
  }

  /// Bir XP-kazandıran aksiyondan sonra çağrılır. Bugün zaten artırıldıysa
  /// no-op; aksi halde streak_days+1 + streak_last_date=today.
  ///
  /// Burada UserProfile'ı dışarıdan alıyoruz çünkü caller zaten elinde
  /// (genelde profileProvider üzerinden) sahip; ekstra round-trip tasarrufu.
  Future<bool> recordActivity(UserProfile profile) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;

    final today = _today();
    final last = profile.streakLastDate;
    if (last != null && _isSameDay(last, today)) return false;

    final isContinuing = last != null && _isYesterday(last, today);
    final newStreak = isContinuing ? profile.streakDays + 1 : 1;

    await _db.from('profiles').update({
      'streak_days': newStreak,
      'streak_last_date': today.toIso8601String(),
      'last_active_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
    return true;
  }

  Future<void> _resetStreak(String userId) async {
    await _db.from('profiles').update({
      'streak_days': 0,
      'streak_last_date': null,
    }).eq('id', userId);
  }

  _StreakDecision _classify({
    required DateTime now,
    required DateTime? lastDate,
  }) {
    if (lastDate == null) return _StreakDecision.firstTime;
    final today = _today(now);
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final diff = today.difference(last).inDays;

    if (diff <= 0) return _StreakDecision.todayAlready;
    if (diff == 1) return _StreakDecision.continuing;
    if (diff == 2) return _StreakDecision.consumeFreeze;
    return _StreakDecision.tooFar;
  }

  DateTime _today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isYesterday(DateTime last, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return _isSameDay(last, yesterday);
  }
}

enum _StreakDecision {
  firstTime,
  todayAlready,
  continuing,
  consumeFreeze,
  tooFar,
}

enum StreakStatus { unchanged, freezeUsed, reset, noSession }

class StreakReconcileResult {
  final StreakStatus status;
  final int? currentStreak;
  final int? freezes;

  const StreakReconcileResult({
    required this.status,
    this.currentStreak,
    this.freezes,
  });
}

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(Supabase.instance.client);
});
