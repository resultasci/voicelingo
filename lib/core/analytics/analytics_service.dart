import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics olayları için tip-güvenli enum + payload.
///
/// İmplementasyon stratejisi (Faz 10):
///   - Şimdilik in-memory no-op + debug log (PostHog/Firebase eklenmediği için)
///   - Production'da [AnalyticsBackend] interface'inin gerçek implementasyonu
///     bootstrap'ta override edilecek. Bu sayede çağrı yerleri (track call'ları)
///     hiç değişmez, sadece backend swap olur.
class AnalyticsService {
  AnalyticsService(this._backend);
  final AnalyticsBackend _backend;

  Future<void> identify(String userId, {Map<String, dynamic>? properties}) {
    return _backend.identify(userId, properties: properties);
  }

  Future<void> track(AnalyticsEvent event, {Map<String, dynamic>? properties}) {
    return _backend.track(event.code, properties: properties);
  }

  Future<void> setUserProperty(String key, dynamic value) {
    return _backend.setUserProperty(key, value);
  }

  Future<void> reset() => _backend.reset();
}

abstract class AnalyticsBackend {
  Future<void> identify(String userId, {Map<String, dynamic>? properties});
  Future<void> track(String event, {Map<String, dynamic>? properties});
  Future<void> setUserProperty(String key, dynamic value);
  Future<void> reset();
}

/// Varsayılan: debug print'e yazar. PostHog/Firebase entegrasyonu yapılana
/// kadar güvenli ve invasive değil.
class DebugAnalyticsBackend implements AnalyticsBackend {
  const DebugAnalyticsBackend();

  @override
  Future<void> identify(String userId,
      {Map<String, dynamic>? properties}) async {
    _log('IDENTIFY $userId props=$properties');
  }

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    _log('TRACK $event props=$properties');
  }

  @override
  Future<void> setUserProperty(String key, dynamic value) async {
    _log('SET_PROP $key=$value');
  }

  @override
  Future<void> reset() async {
    _log('RESET');
  }

  void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[analytics] $msg');
    }
  }
}

/// Tip-güvenli event kataloğu — yeni event eklerken buraya ekle, böylece
/// raporlama anahtarları repository-wide tek kaynaktan tutulur.
enum AnalyticsEvent {
  appOpened('app_opened'),
  sessionStarted('session_started'),
  // Onboarding
  onboardingStarted('onboarding_started'),
  onboardingStepCompleted('onboarding_step_completed'),
  onboardingCompleted('onboarding_completed'),
  // Conversation
  conversationStarted('conversation_started'),
  conversationTurnCompleted('conversation_turn_completed'),
  // Words
  wordAdded('word_added'),
  wordReviewed('word_reviewed'),
  wordMastered('word_mastered'),
  // Lessons
  lessonStarted('lesson_started'),
  lessonCompleted('lesson_completed'),
  // Gamification
  badgeEarned('badge_earned'),
  questCompleted('quest_completed'),
  streakContinued('streak_continued'),
  streakLost('streak_lost'),
  // Scenarios
  scenarioGenerated('scenario_generated'),
  scenarioStarted('scenario_started'),
  // Settings
  characterChanged('character_changed'),
  languageChanged('language_changed'),
  // Errors
  apiError('api_error'),
  audioPermissionDenied('audio_permission_denied');

  final String code;
  const AnalyticsEvent(this.code);
}

final analyticsBackendProvider = Provider<AnalyticsBackend>((ref) {
  // Bootstrap'ta override edilebilir: PostHog/Firebase backend ile değiştir.
  return const DebugAnalyticsBackend();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(analyticsBackendProvider));
});
