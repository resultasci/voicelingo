import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/profile_provider.dart';

/// Profil yazma yolları — ekranlar `Supabase.instance`'a dokunmaz.
class ProfileRepository {
  ProfileRepository(this._db);
  final SupabaseClient _db;

  /// Placement sonucunu profiles.cefr_level'a yazar ve Hive'daki profil
  /// cache'ini düşürür (eski profil tekrar servis edilmesin).
  ///
  /// DB yazımı best-effort: başarısız olsa da Settings'teki placementDone
  /// cache'i HomeScreen'i gate'lemeye devam eder.
  Future<void> saveCefrLevel(String cefr) async {
    final user = _db.auth.currentUser;
    if (user != null) {
      try {
        await _db
            .from('profiles')
            .update({'cefr_level': cefr}).eq('id', user.id);
      } catch (_) {
        // best-effort
      }
    }
    await bustProfileCache();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(Supabase.instance.client),
);
