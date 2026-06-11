import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_profile.dart';
import '../services/profile_repository.dart';

// bustProfileCache tarihsel olarak buradan import edilir; tanım repository'ye
// taşındı (provider → repository tek yönlü import kalsın diye).
export '../services/profile_repository.dart' show bustProfileCache;

/// Read-through Hive cache + Supabase select-first (mantık:
/// [ProfileRepository.fetchOrCreate]).
///
/// First emission: cached profile if present (instant UI on cold start).
/// Cache TTL is 6h — profile drifts (XP, streak) faster than content tables,
/// so we accept the staleness window; writers bust via [bustProfileCache].
final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    return await ref.watch(profileRepositoryProvider).fetchOrCreate();
  } catch (_) {
    // Network down + no cache → ephemeral default so the UI doesn't lock up.
    return UserProfile(
      id: user.id,
      username: user.email?.split('@').first ?? 'Kullanıcı',
      level: 1,
      xp: 0,
      streakDays: 0,
      targetLanguage: 'en',
      streakLastDate: null,
    );
  }
});
