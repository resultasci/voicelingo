import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../auth_validators.dart';

enum AuthMode { signIn, signUp }

/// Login/kayıt ekranı hata kodları — controller BuildContext tutmadığı için
/// lokalize metne çeviri widget tarafında (build sırasında) yapılır.
enum AuthError {
  emptyFields,
  emptyName,
  invalidEmail,
  passwordTooShort,
  invalidCredentials,
  emailNotConfirmed,
  alreadyRegistered,
  network,
  generic,
}

/// Login/kayıt ekranının iş mantığı: mod geçişi, doğrulama, submit ve hata
/// eşleme. Sözleşme [ConversationController] ile aynı: State'in sahip olduğu
/// ChangeNotifier, fonksiyon-enjekte bağımlılıklar, BuildContext yok.
class AuthController extends ChangeNotifier {
  AuthController({
    required Future<void> Function(String email, String password) signIn,
    required Future<void> Function(String email, String password,
            {String? username})
        signUp,
  })  : _signIn = signIn,
        _signUp = signUp;

  final Future<void> Function(String email, String password) _signIn;
  final Future<void> Function(String email, String password, {String? username})
      _signUp;

  AuthMode _mode = AuthMode.signIn;
  AuthMode get mode => _mode;
  bool get isLogin => _mode == AuthMode.signIn;

  bool _submitting = false;
  bool get submitting => _submitting;

  AuthError? _error;
  AuthError? get error => _error;

  /// signUp başarıyla tamamlandı — "e-postanı doğrula" ekranı gösterilmeli.
  bool _confirmEmailPending = false;
  bool get confirmEmailPending => _confirmEmailPending;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void toggleMode() {
    _mode = isLogin ? AuthMode.signUp : AuthMode.signIn;
    _error = null;
    _notify();
  }

  /// Doğrulama ekranından login'e dönüş.
  void dismissConfirmEmail() {
    _confirmEmailPending = false;
    _mode = AuthMode.signIn;
    _notify();
  }

  Future<void> submit({
    required String email,
    required String password,
    required String name,
  }) async {
    final fieldError = isLogin
        ? validateSignIn(email: email, password: password)
        : validateSignUp(email: email, password: password, name: name);
    if (fieldError != null) {
      _error = _fromFieldError(fieldError);
      _notify();
      return;
    }

    _submitting = true;
    _error = null;
    _notify();
    try {
      if (isLogin) {
        await _signIn(email.trim(), password.trim());
      } else {
        await _signUp(email.trim(), password.trim(), username: name.trim());
        _confirmEmailPending = true;
      }
    } on AppException catch (e) {
      _error = mapAuthException(e);
    } catch (_) {
      _error = AuthError.generic;
    } finally {
      _submitting = false;
      _notify();
    }
  }

  static AuthError _fromFieldError(AuthFieldError e) => switch (e) {
        AuthFieldError.emptyFields => AuthError.emptyFields,
        AuthFieldError.emptyName => AuthError.emptyName,
        AuthFieldError.invalidEmail => AuthError.invalidEmail,
        AuthFieldError.passwordTooShort => AuthError.passwordTooShort,
        AuthFieldError.passwordsDontMatch => AuthError.generic,
      };

  /// Supabase'in makine-okur hata kodu önceliklidir; kod yoksa eski
  /// mesaj-koklama davranışı korunur (geri uyumluluk).
  @visibleForTesting
  static AuthError mapAuthException(AppException e) {
    if (e is NetworkException || e is OfflineException) {
      return AuthError.network;
    }
    switch (e.code) {
      case 'invalid_credentials':
        return AuthError.invalidCredentials;
      case 'email_not_confirmed':
        return AuthError.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AuthError.alreadyRegistered;
      case 'weak_password':
        return AuthError.passwordTooShort;
    }
    final s = e.message.toLowerCase();
    if (s.contains('invalid login') || s.contains('invalid credentials')) {
      return AuthError.invalidCredentials;
    }
    if (s.contains('email') && s.contains('confirm')) {
      return AuthError.emailNotConfirmed;
    }
    if (s.contains('user already') || s.contains('already registered')) {
      return AuthError.alreadyRegistered;
    }
    if (s.contains('password') && s.contains('6')) {
      return AuthError.passwordTooShort;
    }
    if (s.contains('network') || s.contains('socket')) {
      return AuthError.network;
    }
    return AuthError.generic;
  }
}
