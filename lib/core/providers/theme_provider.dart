import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

/// Single source of truth for the app's [ThemeMode]. Backed by SharedPreferences
/// via [SettingsService] so changes survive restarts.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(settingsServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._settings) : super(_decode(_settings.themeMode));

  final SettingsService _settings;

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
    await _settings.setThemeMode(_encode(mode));
  }
}

/// Accessibility: kullanıcının yazı boyutu çarpanı.
/// MediaQuery.textScaler'a uygulanır ([app/app.dart]).
final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, double>((ref) {
  return TextScaleNotifier(ref.watch(settingsServiceProvider));
});

class TextScaleNotifier extends StateNotifier<double> {
  TextScaleNotifier(this._settings) : super(_settings.textScale);

  final SettingsService _settings;

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.5);
    state = clamped;
    await _settings.setTextScale(clamped);
  }
}
