import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge.dart';
import '../models/daily_quest.dart';
import '../services/badges_service.dart';
import '../services/daily_quests_service.dart';

// =============================================================================
// Service providers
// =============================================================================
final badgesServiceProvider = Provider<BadgesService>((ref) {
  return BadgesService(Supabase.instance.client);
});

final dailyQuestsServiceProvider = Provider<DailyQuestsService>((ref) {
  return DailyQuestsService(Supabase.instance.client);
});

// =============================================================================
// Reactive state providers
// =============================================================================

/// Tüm rozet kataloğu (statik, sonsuza dek cache'lenebilir — seed verisi).
final badgesCatalogProvider = FutureProvider<List<LearningBadge>>((ref) async {
  final svc = ref.watch(badgesServiceProvider);
  return svc.listAll();
});

/// Kullanıcının kazandığı rozetler. XP veya badge unlock'ta invalidate edilir.
final earnedBadgesProvider =
    FutureProvider.autoDispose<List<EarnedBadge>>((ref) async {
  final svc = ref.watch(badgesServiceProvider);
  return svc.listEarned();
});

/// Bugünkü daily quest listesi. Boş ise generate edilir.
final dailyQuestsProvider =
    FutureProvider.autoDispose<List<DailyQuest>>((ref) async {
  final svc = ref.watch(dailyQuestsServiceProvider);
  return svc.ensureToday();
});

/// Bugün tamamlanmış quest sayısı — dashboard'da gösterilir.
final completedQuestsTodayProvider = Provider.autoDispose<int>((ref) {
  final quests = ref.watch(dailyQuestsProvider).value ?? const [];
  return quests.where((q) => q.isCompleted).length;
});
