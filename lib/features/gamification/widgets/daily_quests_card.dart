import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/daily_quest.dart';
import '../providers/gamification_providers.dart';

/// Dashboard'daki günlük görev paneli — 3 quest satırı: ikon, etiket,
/// progress bar, XP çipi; tamamlananlar tik + soluk stil ile gösterilir.
class DailyQuestsCard extends ConsumerWidget {
  const DailyQuestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final questsAsync = ref.watch(dailyQuestsProvider);

    return questsAsync.when(
      loading: () => const _QuestsSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quests) {
        if (quests.isEmpty) return const SizedBox.shrink();
        final done = ref.watch(completedQuestsTodayProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.quests_title,
                    style: AppText.title(20,
                        color: c.ink, weight: FontWeight.w600),
                  ),
                ),
                NeonChip(
                  text: l.quests_completed(done, quests.length),
                  icon: Icons.flag_outlined,
                  color:
                      done == quests.length ? c.secondary : c.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 14),
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              glowColor: c.primaryContainer,
              child: Column(
                children: [
                  for (var i = 0; i < quests.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.surfaceHighest),
                    _QuestRow(quest: quests[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});
  final DailyQuest quest;

  static const _icons = <QuestType, IconData>{
    QuestType.learnWords: Icons.auto_stories_outlined,
    QuestType.reviewWords: Icons.replay_circle_filled_outlined,
    QuestType.practiceMinutes: Icons.timer_outlined,
    QuestType.conversationTurns: Icons.forum_outlined,
    QuestType.perfectScore: Icons.workspace_premium_outlined,
  };

  String _label(AppL10n l) => switch (quest.type) {
        QuestType.learnWords => l.quest_learnWords,
        QuestType.reviewWords => l.quest_reviewWords,
        QuestType.practiceMinutes => l.quest_practiceMinutes,
        QuestType.conversationTurns => l.quest_conversationTurns,
        QuestType.perfectScore => l.quest_perfectScore,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final completed = quest.isCompleted;
    final accent = completed ? c.secondary : c.primaryContainer;

    return Opacity(
      opacity: completed ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : _icons[quest.type],
              color: accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(l),
                    style: AppText.ink(13,
                        color: c.ink,
                        weight: completed ? FontWeight.w400 : FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: quest.progressRatio,
                      minHeight: 5,
                      backgroundColor: c.surfaceHighest,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              completed
                  ? l.quests_completed(quest.target, quest.target)
                  : l.quests_completed(quest.progress, quest.target),
              style:
                  AppText.label(10, color: c.inkDim, weight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            Text(
              l.quests_xp(quest.xpReward),
              style: AppText.label(10, color: accent, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestsSkeleton extends StatelessWidget {
  const _QuestsSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = context.c.surfaceHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: context.c.surfaceHighest,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
