/// Tüm domain hataları için ortak taban sınıf.
///
/// Eski özel exception sınıfları (`AiException`, `DuplicateWordException`,
/// `AccountException`) bu hiyerarşiye bağlandı — `is AppException` ile tek
/// noktada yakalanabilirler.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => '${runtimeType.toString()}: $message';
}

/// İnternet/ağ erişim hataları (timeout, no connection, DNS, vs.).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

/// Cihaz çevrimdışıyken çevrimiçi-zorunlu bir işlem denenmesi.
class OfflineException extends AppException {
  const OfflineException([super.message = 'Çevrimdışı moddasın.']);
}

/// Sunucu tarafı rate limit (429).
class RateLimitException extends AppException {
  final Duration? retryAfter;
  const RateLimitException(super.message, {this.retryAfter, super.code});
}

/// Kullanıcı girdisi doğrulama hataları (form, parametre, vb.).
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  const ValidationException(super.message, {this.fieldErrors, super.code});
}

/// Kimlik/oturum hataları (oturum yok, token expired, izin reddedildi).
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

/// Beklenmeyen, sınıflandırılmamış hatalar — genellikle bug habercisidir.
class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause})
      : super(code: 'unexpected');
}

/// ai-proxy Edge Function'dan dönen hata cevapları (statusCode + mesaj).
/// GeminiService sınırda fırlatır; `error_handler.dart` statusCode'a göre
/// lokalize mesaja çevirir.
class AiException extends AppException {
  final int statusCode;
  AiException(this.statusCode, String message)
      : super(message, code: 'ai_$statusCode');

  bool get isRateLimit => statusCode == 429;
  bool get isAuth => statusCode == 401;

  @override
  String toString() => message;
}
