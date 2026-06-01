import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/storage/cached_repository.dart';
import '../core/storage/hive_boxes.dart';
import '../models/user_profile.dart';

/// Read-through Hive cache + Supabase upsert+select.
///
/// First emission: cached profile if present (instant UI on cold start).
/// Second emission: fresh row from Supabase. Cache TTL is 6h — profile drifts
/// (XP, streak) faster than content tables, so we accept the staleness window.
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
