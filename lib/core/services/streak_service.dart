import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streak reset + freeze tüketimi.
///
/// Streak ARTIRIMI DB tarafındadır (log_practice_session vb. RPC'ler);
/// bu servis yalnız gün atlamalarını cold start'ta toparlar çünkü:
///   - Cron schedule güvenilmez (Supabase Edge Function cron'ları kullanıcı bağımsız)
///   - Streak reset her cold start'ta hesaplanırsa "tam zamanında" güncellenir
///
/// Algoritma (her app açılışında [reconcile] çağırılır — bootstrap.dart):
///   1. `streakLastDate` bugün veya dün → streak korunur
///   2. `streakLastDate` 2 gün önce → 1 streak_freeze varsa harca, yoksa streak=0
///   3. `streakLastDate` 3+ gün önce → streak=0 (freeze yetmez)
///   4. `streakLastDate` null → değişiklik yok (hiç aktivite olmamış)
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
          // Freeze KAÇIRILAN günü (dünü) kapatır; last_date dün yapılır ki
          // bugünkü aktivite DB tarafında streak'i normal +1 artırabilsin ve
          // arka arkaya kaçırılan her gün ayrı freeze tüketsin.
          final yesterday = _today().subtract(const Duration(days: 1));
          await _db.from('profiles').update({
            'streak_freezes': freezes - 1,
            'streak_last_date': yesterday.toIso8601String(),
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
