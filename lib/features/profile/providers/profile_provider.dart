import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/perf/perf_trace.dart';
import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';

/// Read-through Hive cache + Supabase upsert+select.
///
/// First emission: cached profile if present (instant UI on cold start).
/// Second emission: fresh row from Supabase. Cache TTL is 6h — profile drifts
/// (XP, streak) faster than content tables, so we accept the staleness window.
/// Drops the Hive entry for the current user's profile. Must be called before
/// `ref.invalidate(profileProvider)` whenever fresh server data is required
/// (XP/streak just changed, pull-to-refresh) — invalidating the provider alone
/// re-serves the cached row until the 6h TTL expires.
Future<void> bustProfileCache() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  await CachedRepository.invalidate(Hive.box<Map>(HiveBoxes.profiles), user.id);
}

final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final box = Hive.box<Map>(HiveBoxes.profiles);

  try {
    return await CachedRepository.getOrFetch<UserProfile>(
      box: box,
      key: user.id,
      fromJson: UserProfile.fromMap,
      toJson: (p) => p.toMap(),
      maxAge: const Duration(hours: 6),
      fetchRemote: () async {
        final done = PerfTrace.span('profile fetchRemote');
        final metaUsername = user.userMetadata?['username'] as String?;
        await supabase.from('profiles').upsert(
          {
            'id': user.id,
            'username': metaUsername?.isNotEmpty == true
                ? metaUsername
                : user.email?.split('@').first ?? 'kullanici',
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
        final data = await supabase
            .from('profiles')
            .select(
                'id,username,level,xp,streak_days,target_language,streak_last_date,seeded_at,cefr_level,streak_freezes,last_active_at,onboarding_completed_at,daily_minute_goal,learning_motivation')
            .eq('id', user.id)
            .single();
        done();
        return UserProfile.fromMap(data);
      },
    );
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
