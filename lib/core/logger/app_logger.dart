import 'dart:developer';

/// Uygulama geneli loglama aracı.
/// Geliştirme aşamasında konsola yazar. Üretimde (Production) hata izleme
/// araçlarına (Örn: Sentry, Crashlytics) entegre edilebilir.
class AppLogger {
  AppLogger._();

  static void info(String message, {String tag = 'INFO'}) {
    log('[$tag] $message');
  }

  static void debug(String message, {String tag = 'DEBUG'}) {
    log('[$tag] $message');
  }

  static void warning(String message, {String tag = 'WARN'}) {
    log('[$tag] $message', level: 900);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    log('[ERROR] $message', error: error, stackTrace: stackTrace, level: 1000);
  }
}
