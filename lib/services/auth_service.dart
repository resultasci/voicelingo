import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  static const String passwordResetRedirect =
      'io.supabase.voicelingo://reset-callback/';

  Future<void> signUp(String email, String password, {String? username}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: username != null && username.isNotEmpty
          ? {'username': username}
          : null,
    );
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordResetRedirect,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) {
      throw const AuthException('Oturum bulunamadı.');
    }
    await _supabase.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;
}
