import 'package:shared_preferences/shared_preferences.dart';

/// Singleton wrapper around SharedPreferences for app-wide user settings.
///
/// Call [SettingsService.init] once at startup before any other access.
class SettingsService {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static late SharedPreferences _prefs;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Theme: 'light' | 'dark' | 'system'
  // ---------------------------------------------------------------------------
  static const _kThemeMode = 'theme_mode';
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'dark';
  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  // ---------------------------------------------------------------------------
  // Interface language: 'tr' | 'en'
  // ---------------------------------------------------------------------------
  static const _kInterfaceLanguage = 'interface_language';
  String get interfaceLanguage => _prefs.getString(_kInterfaceLanguage) ?? 'tr';
  Future<void> setInterfaceLanguage(String lang) =>
      _prefs.setString(_kInterfaceLanguage, lang);

  // ---------------------------------------------------------------------------
  // TTS rate: 0.5 | 0.75 | 1.0
  // ---------------------------------------------------------------------------
  static const _kTtsRate = 'tts_rate';
  double get ttsRate => _prefs.getDouble(_kTtsRate) ?? 0.5;
  Future<void> setTtsRate(double rate) => _prefs.setDouble(_kTtsRate, rate);

  // ---------------------------------------------------------------------------
  // Daily review reminder hour (0-23, default 19)
  // ---------------------------------------------------------------------------
  static const _kReviewHour = 'review_hour';
  int get reviewHour => _prefs.getInt(_kReviewHour) ?? 19;
  Future<void> setReviewHour(int hour) =>
      _prefs.setInt(_kReviewHour, hour.clamp(0, 23));

  // ---------------------------------------------------------------------------
  // Notification toggle
  // ---------------------------------------------------------------------------
  static const _kNotificationsEnabled = 'notifications_enabled';
  bool get notificationsEnabled =>
      _prefs.getBool(_kNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(_kNotificationsEnabled, v);

  // ---------------------------------------------------------------------------
  // Placement test completion gate (per-device cache; the source of truth is
  // profiles.cefr_level, but reading prefs avoids a Supabase round-trip on
  // every cold start of HomeScreen).
  // ---------------------------------------------------------------------------
  static const _kPlacementDone = 'placement_done';
  bool get placementDone => _prefs.getBool(_kPlacementDone) ?? false;
  Future<void> setPlacementDone(bool v) => _prefs.setBool(_kPlacementDone, v);

  // ---------------------------------------------------------------------------
  // Onboarding completion gate (per-device cache; the source of truth is
  // profiles.onboarding_completed_at).
  // ---------------------------------------------------------------------------
  static const _kOnboardingDone = 'onboarding_done';
  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) => _prefs.setBool(_kOnboardingDone, v);

  // ---------------------------------------------------------------------------
  // Accessibility: text scale factor (0.85 - 1.5, default 1.0)
  // MediaQuery.textScaler'a uygulanır; sistem ayarını override eder.
  // ---------------------------------------------------------------------------
  static const _kTextScale = 'text_scale';
  double get textScale => _prefs.getDouble(_kTextScale) ?? 1.0;
  Future<void> setTextScale(double scale) =>
      _prefs.setDouble(_kTextScale, scale.clamp(0.85, 1.5));
}
