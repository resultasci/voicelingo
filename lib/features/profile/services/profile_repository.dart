import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/perf/perf_trace.dart';
import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';

/// Drops the Hive entry for the current user's profile. Must be called before
/// `ref.invalidate(profileProvider)` whenever fresh server data is required
/// (XP/streak just changed, pull-to-refresh) — invalidating the provider alone
/// re-serves the cached row until the 6h TTL expires.
Future<void> bustProfileCache() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  await CachedRepository.invalidate(Hive.box<Map>(HiveBoxes.profiles), user.id);
}

/// Profil okuma/yazma yolları — ekranlar `Supabase.instance`'a dokunmaz.
class ProfileRepository {
  ProfileRepository(this._db);
  final SupabaseClient _db;

  static const _columns =
      'id,username,level,xp,streak_days,target_language,streak_last_date,seeded_at,cefr_level,streak_freezes,last_active_at,onboarding_completed_at,daily_minute_goal,learning_motivation';
  static const _cacheMaxAge = Duration(hours: 6);

  /// Eş-zamanlı prewarm + provider fetch'ini tek uçuşa indirger. Bootstrap
  /// kendi instance'ını kurduğu için (ProviderScope henüz yok) static.
  static Future<UserProfile?>? _inflight;

  /// Read-through Hive cache + Supabase select-first.
  ///
  /// Cache hit: anında döner, arka planda tazelenir (SWR). Cache miss: sıcak
  /// yol TEK round-trip'tir (select); satır yoksa (ilk giriş) upsert + select.
  /// Oturum yoksa null. Ağ hatası cache'siz durumda fırlar — çağıran karar
  /// verir (provider ephemeral default üretir, prewarm yutar).
  Future<UserProfile?> fetchOrCreate() {
    return _inflight ??=
        _doFetchOrCreate().whenComplete(() => _inflight = null);
  }

  Future<UserProfile?> _doFetchOrCreate() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return CachedRepository.getOrFetch<UserProfile>(
      box: Hive.box<Map>(HiveBoxes.profiles),
      key: user.id,
      fromJson: UserProfile.fromMap,
      toJson: (p) => p.toMap(),
      maxAge: _cacheMaxAge,
      fetchRemote: () => _fetchRemote(user),
    );
  }

  Future<UserProfile> _fetchRemote(User user) async {
    final done = PerfTrace.span('profile fetchRemote');
    // Sıcak yol tek round-trip: satır zaten varsa select yeter. Upsert
    // `ignoreDuplicates: true` (ON CONFLICT DO NOTHING) satır DÖNDÜRMEDİĞİ
    // için upsert+returning tek çağrıya indirilemez — upsert yalnız ilk
    // girişte (satır yokken) çalışır.
    final existing = await _db
        .from('profiles')
        .select(_columns)
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) {
      done();
      return UserProfile.fromMap(existing);
    }

    final metaUsername = user.userMetadata?['username'] as String?;
    await _db.from('profiles').upsert(
      {
        'id': user.id,
        'username': metaUsername?.isNotEmpty == true
            ? metaUsername
            : user.email?.split('@').first ?? 'kullanici',
      },
      onConflict: 'id',
      ignoreDuplicates: true,
    );
    final data = await _db
        .from('profiles')
        .select(_columns)
        .eq('id', user.id)
        .single();
    done();
    return UserProfile.fromMap(data);
  }

  /// Boot sonrası fire-and-forget ön ısıtma: HomeScreen post-frame'de profili
  /// istediğinde Hive girdisi sıcak ya da aynı fetch zaten uçuşta olur.
  /// Oturum yoksa no-op; hatalar yutulur (provider yolu kendi ephemeral
  /// fallback'ini üretir).
  Future<void> prewarm() async {
    if (_db.auth.currentUser == null) return;
    try {
      await fetchOrCreate();
    } catch (_) {
      // best-effort
    }
  }

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
