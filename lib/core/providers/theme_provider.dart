import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

/// Single source of truth for the app's [ThemeMode]. Backed by SharedPreferences
/// via [SettingsService] so changes survive restarts.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_decode(SettingsService().themeMode));

  static ThemeMode _decode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await SettingsService().setThemeMode(_encode(mode));
  }
}

/// Accessibility: kullanıcının yazı boyutu çarpanı.
/// MediaQuery.textScaler'a uygulanır ([app/app.dart]).
final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, double>((ref) {
  return TextScaleNotifier();
});

class TextScaleNotifier extends StateNotifier<double> {
  TextScaleNotifier() : super(SettingsService().textScale);

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.5);
    state = clamped;
    await SettingsService().setTextScale(clamped);
  }
}
