import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicelingo/core/services/settings_service.dart';

Future<SettingsService> makeService(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return SettingsService(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults when prefs are empty', () async {
    final s = await makeService({});
    expect(s.themeMode, 'dark');
    expect(s.interfaceLanguage, 'tr');
    expect(s.ttsRate, 0.5);
    expect(s.reviewHour, 19);
    expect(s.notificationsEnabled, isTrue);
    expect(s.placementDone, isFalse);
    expect(s.onboardingDone, isFalse);
    expect(s.textScale, 1.0);
  });

  test('persisted values round-trip', () async {
    final s = await makeService({});
    await s.setThemeMode('light');
    await s.setInterfaceLanguage('en');
    await s.setTtsRate(0.75);
    await s.setPlacementDone(true);
    await s.setOnboardingDone(true);
    expect(s.themeMode, 'light');
    expect(s.interfaceLanguage, 'en');
    expect(s.ttsRate, 0.75);
    expect(s.placementDone, isTrue);
    expect(s.onboardingDone, isTrue);
  });

  test('reviewHour clamps to 0-23', () async {
    final s = await makeService({});
    await s.setReviewHour(99);
    expect(s.reviewHour, 23);
    await s.setReviewHour(-5);
    expect(s.reviewHour, 0);
  });

  test('textScale clamps to 0.85-1.5', () async {
    final s = await makeService({});
    await s.setTextScale(3.0);
    expect(s.textScale, 1.5);
    await s.setTextScale(0.1);
    expect(s.textScale, 0.85);
  });
}
