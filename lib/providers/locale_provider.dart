import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

/// Kullanıcı arayüz dili. SettingsService'te `interfaceLanguage` (tr/en)
/// olarak saklanır; MaterialApp.locale'a bağlanır.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_decode(SettingsService().interfaceLanguage));

  static Locale _decode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en');
      case 'tr':
      default:
        return const Locale('tr');
    }
  }

  Future<void> setLanguage(String code) async {
    final normalized = code == 'en' ? 'en' : 'tr';
    state = _decode(normalized);
    await SettingsService().setInterfaceLanguage(normalized);
  }
}
