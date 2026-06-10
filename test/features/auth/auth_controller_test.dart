import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/errors/app_exception.dart';
import 'package:voicelingo/features/auth/auth_validators.dart';
import 'package:voicelingo/features/auth/controllers/auth_controller.dart';

AuthController makeController({
  Future<void> Function(String, String)? signIn,
  Future<void> Function(String, String, {String? username})? signUp,
}) {
  return AuthController(
    signIn: signIn ?? (_, __) async {},
    signUp: signUp ?? (_, __, {username}) async {},
  );
}

void main() {
  group('auth_validators', () {
    test('validateSignIn rejects empty fields then bad email', () {
      expect(
          validateSignIn(email: '', password: 'x'), AuthFieldError.emptyFields);
      expect(validateSignIn(email: 'a@b.co', password: ''),
          AuthFieldError.emptyFields);
      expect(validateSignIn(email: 'not-an-email', password: '123456'),
          AuthFieldError.invalidEmail);
      expect(validateSignIn(email: 'a@b.co', password: '123456'), isNull);
    });

    test('validateSignUp requires name and strong-enough password', () {
      expect(validateSignUp(email: 'a@b.co', password: '123456', name: ''),
          AuthFieldError.emptyName);
      expect(validateSignUp(email: 'a@b.co', password: '12345', name: 'Ada'),
          AuthFieldError.passwordTooShort);
      expect(validateSignUp(email: 'a@b.co', password: '123456', name: 'Ada'),
          isNull);
    });

    test('validateNewPassword enforces match and min length', () {
      expect(validateNewPassword(password: '', confirm: ''),
          AuthFieldError.emptyFields);
      expect(validateNewPassword(password: '12345', confirm: '12345'),
          AuthFieldError.passwordTooShort);
      expect(validateNewPassword(password: '123456', confirm: '654321'),
          AuthFieldError.passwordsDontMatch);
      expect(
          validateNewPassword(password: '123456', confirm: '123456'), isNull);
    });
  });

  group('AuthController.submit', () {
    test('validation error stops submit before calling the service', () async {
      var called = false;
      final c = makeController(signIn: (_, __) async => called = true);
      await c.submit(email: '', password: '', name: '');
      expect(c.error, AuthError.emptyFields);
      expect(called, isFalse);
    });

    test('successful signIn clears error and submitting', () async {
      final c = makeController();
      await c.submit(email: 'a@b.co', password: '123456', name: '');
      expect(c.error, isNull);
      expect(c.submitting, isFalse);
      expect(c.confirmEmailPending, isFalse);
    });

    test('successful signUp sets confirmEmailPending', () async {
      final c = makeController();
      c.toggleMode(); // signUp
      await c.submit(email: 'a@b.co', password: '123456', name: 'Ada');
      expect(c.confirmEmailPending, isTrue);
      expect(c.error, isNull);
    });

    test('AppException maps to error enum, generic for unknown', () async {
      final c = makeController(
        signIn: (_, __) async =>
            throw const AuthException('Invalid login credentials'),
      );
      await c.submit(email: 'a@b.co', password: '123456', name: '');
      expect(c.error, AuthError.invalidCredentials);
      expect(c.submitting, isFalse);

      final c2 = makeController(signIn: (_, __) async => throw StateError('x'));
      await c2.submit(email: 'a@b.co', password: '123456', name: '');
      expect(c2.error, AuthError.generic);
    });

    test('toggleMode flips mode and clears previous error', () async {
      final c = makeController();
      await c.submit(email: '', password: '', name: '');
      expect(c.error, isNotNull);
      c.toggleMode();
      expect(c.isLogin, isFalse);
      expect(c.error, isNull);
    });
  });

  group('AuthController.mapAuthException', () {
    test('prefers machine-readable codes over message sniffing', () {
      expect(
        AuthController.mapAuthException(
            const AuthException('x', code: 'invalid_credentials')),
        AuthError.invalidCredentials,
      );
      expect(
        AuthController.mapAuthException(
            const AuthException('x', code: 'email_not_confirmed')),
        AuthError.emailNotConfirmed,
      );
      expect(
        AuthController.mapAuthException(
            const AuthException('x', code: 'user_already_exists')),
        AuthError.alreadyRegistered,
      );
      expect(
        AuthController.mapAuthException(
            const AuthException('x', code: 'weak_password')),
        AuthError.passwordTooShort,
      );
    });

    test('falls back to legacy message matching', () {
      expect(
        AuthController.mapAuthException(
            const AuthException('Email not confirmed')),
        AuthError.emailNotConfirmed,
      );
      expect(
        AuthController.mapAuthException(
            const AuthException('User already registered')),
        AuthError.alreadyRegistered,
      );
      expect(
        AuthController.mapAuthException(const NetworkException('timeout')),
        AuthError.network,
      );
      expect(
        AuthController.mapAuthException(const AuthException('???')),
        AuthError.generic,
      );
    });
  });
}
