import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/hive_boxes.dart';

/// Supabase auth sarmalayıcısı.
///
/// Sınır kuralı: Supabase'in kendi `AuthException`'ı burada yakalanır ve
/// hiyerarşimizdeki [AuthException]'a çevrilir — üst katmanlar üçüncü parti
/// hata tipi görmez. (İki sınıfın adı aynıdır; bu dosyada Supabase tarafı
/// `supa.` öneki ile ayrışır.)
class AuthService {
  final _supabase = supa.Supabase.instance.client;

  static const String passwordResetRedirect =
      'io.supabase.voicelingo://reset-callback/';

  Future<T> _translate<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.code, cause: e);
    }
  }

  Future<void> signUp(String email, String password, {String? username}) =>
      _translate(() => _supabase.auth.signUp(
            email: email,
            password: password,
            data: username != null && username.isNotEmpty
                ? {'username': username}
                : null,
          ));

  Future<void> signIn(String email, String password) =>
      _translate(() => _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          ));

  Future<void> signOut() async {
    await _translate(() => _supabase.auth.signOut());
    // Kullanıcıya özel offline cache'ler bir sonraki hesaba sızmasın.
    try {
      await HiveBoxes.clearUserData();
    } catch (_) {
      // Cache temizliği best-effort; çıkışı asla engellemesin.
    }
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _translate(() => _supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: passwordResetRedirect,
          ));

  Future<void> updatePassword(String newPassword) =>
      _translate(() => _supabase.auth.updateUser(
            supa.UserAttributes(password: newPassword),
          ));

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _translate(() async {
        final email = _supabase.auth.currentUser?.email;
        if (email == null) {
          throw const AuthException('Oturum bulunamadı.', code: 'no_session');
        }
        await _supabase.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
        await _supabase.auth.updateUser(
          supa.UserAttributes(password: newPassword),
        );
      });

  Stream<supa.AuthState> get authStateStream =>
      _supabase.auth.onAuthStateChange;

  supa.User? get currentUser => _supabase.auth.currentUser;
}
