import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/settings_service.dart';

/// Onboarding state'i + completion handler.
///
/// Onboarding data:
///   - Günlük dakika hedefi (5/10/20/30)
///   - Öğrenme motivasyonu (work/exam/travel/hobby)
///   - Mikrofon + bildirim izinleri durumu
///
/// Tamamlanma:
///   - profiles.onboarding_completed_at set edilir
///   - SettingsService'e local cache yazılır (router redirect için)
class OnboardingService {
  OnboardingService(this._db);
  final SupabaseClient _db;

  /// Hedef + motivasyon kaydedilir.
  Future<void> savePreferences({
    required int dailyMinuteGoal,
    required String motivation,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db.from('profiles').update({
      'daily_minute_goal': dailyMinuteGoal,
      'learning_motivation': motivation,
    }).eq('id', user.id);
  }

  /// Onboarding flow'un sonunda çağrılır.
  Future<void> complete() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.from('profiles').update({
      'onboarding_completed_at': nowIso,
      'last_active_at': nowIso,
    }).eq('id', user.id);
    await SettingsService().setOnboardingDone(true);
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(Supabase.instance.client);
});
