import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tüm `.env` ve `--dart-define` değerlerine tip-güvenli erişim.
///
/// `dotenv.env['X']!` dağıtımı yerine bu sınıfı kullan; eksik anahtarlar
/// derleme/runtime hatası vermek yerine kontrollü `ConfigException` fırlatır.
class Env {
  Env._();

  static String _required(String key) {
    final v = dotenv.env[key];
    if (v == null || v.trim().isEmpty) {
      throw EnvException(
          '$key tanımlı değil veya boş — .env dosyasını kontrol et.');
    }
    return v;
  }

  // --- .env'den ---
  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  // --- --dart-define'dan ---
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static bool get isProduction => appEnv == 'production';
}

class EnvException implements Exception {
  final String message;
  EnvException(this.message);
  @override
  String toString() => 'EnvException: $message';
}
