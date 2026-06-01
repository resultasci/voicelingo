import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hassas veriler için OS-seviye keystore wrapper'ı.
///
/// Supabase auth token'larını şu an SharedPreferences'ta tutuyor;
/// kendi sakladığımız hassas veriler (örn. OpenAI API anahtarı, kullanıcı
/// tercihi şifrelenmiş custom data) buraya gelir.
///
/// Android: EncryptedSharedPreferences
/// iOS: Keychain
class SecureStorage {
  SecureStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  ));
});
