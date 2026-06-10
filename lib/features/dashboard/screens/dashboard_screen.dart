import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../../../providers/nav_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/words_provider.dart';
import '../../../theme/app_theme.dart';
import '../../gamification/providers/gamification_providers.dart';
import '../../gamification/widgets/daily_quests_card.dart';
import '../../words/screens/flashcard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final profileAsync = ref.watch(profileProvider);
    final wordsAsync = ref.watch(wordsProvider);

    final initialLoading = profileAsync.isLoading && wordsAsync.value == null;

    return RefreshIndicator(
      color: context.c.primaryContainer,
      backgroundColor: context.c.bgCard,
      onRefresh: () async {
        await bustProfileCache();
        ref.invalidate(profileProvider);
        ref.invalidate(dailyQuestsProvider);
        await ref.read(wordsProvider.notifier).load(forceRefresh: true);
      },
      child: initialLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: const [_DashboardSkeleton()],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                profileAsync.when(
                  data: (p) => _Welcome(profile: p),
                  loading: () => const _LoadingDot(),
                  error: (e, _) => _ErrorBlock(
                    message: l.dashboard_profileLoadError,
                    onRetry: () => ref.invalidate(profileProvider),
                  ),
                ),
                const SizedBox(height: 28),
                _StatsHud(
                  profile: profileAsync.value,
                  wordCount: wordsAsync.value?.length ?? 0,
                ),
                const SizedBox(height: 24),
                _AiPracticeCard(
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                ),
                const SizedBox(height: 28),
                const DailyQuestsCard(),
                const SizedBox(height: 28),
                wordsAsync.when(
                  data: (words) {
                    final due = words.where((w) => w.isDue).toList();
                    final total = words.length;
                    return _DailyGoals(
                      due: due.length,
                      total: total,
                      onTap: () {
                        if (due.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => FlashcardScreen(dueWords: due)),
                          );
                        } else {
                          ref.read(selectedTabProvider.notifier).state = 1;
                        }
                      },
                    );
                  },
                  loading: () => const _LoadingDot(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = context.c.surfaceHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: context.c.surfaceHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(width: 220, height: 28, color: base),
          const SizedBox(height: 12),
          _bar(width: 280, height: 14, color: base),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _block(height: 84, color: base)),
              const SizedBox(width: 14),
              Expanded(child: _block(height: 84, color: base)),
            ],
          ),
          const SizedBox(height: 24),
          _block(height: 180, color: base),
          const SizedBox(height: 28),
          _bar(width: 160, height: 18, color: base),
          const SizedBox(height: 14),
          _block(height: 92, color: base),
          const SizedBox(height: 12),
          _block(height: 92, color: base),
        ],
      ),
    );
  }

  Widget _bar(
      {required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _block({required double height, required Color color}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// =============================================================================
class _Welcome extends StatelessWidget {
  final UserProfile? profile;
  const _Welcome({this.profile});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final name = profile?.username ?? l.dashboard_defaultName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.dashboard_greeting(name),
          style: AppText.hero(32, color: c.primary, weight: FontWeight.w700)
              .copyWith(
            shadows: neonGlow(c.primary, blur: 10, opacity: 0.3),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.dashboard_greetingSubtitle,
          style: AppText.body(15, color: c.inkMuted),
        ),
      ],
    );
  }
}

// =============================================================================
class _StatsHud extends StatelessWidget {
  final UserProfile? profile;
  final int wordCount;
  const _StatsHud({this.profile, required this.wordCount});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final streak = profile?.streakDays ?? 0;
    final xp = profile?.xp ?? 0;
    return Row(
      children: [
        Expanded(
          child: _HudTile(
            icon: Icons.local_fire_department,
            iconColor: c.secondary,
            iconBg: c.secondaryContainer,
            label: l.dashboard_statStreak,
            value: l.dashboard_streakValue(streak),
            valueColor: c.secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _HudTile(
            icon: Icons.auto_awesome,
            iconColor: c.primaryFixedDim,
            iconBg: c.primaryContainer,
            label: 'XP',
            value: _fmt(xp),
            valueColor: c.primaryFixedDim,
          ),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n < 1000) return '$n';
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
}

class _HudTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  const _HudTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      glowColor: iconBg,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg.withOpacity(0.18),
              border: Border.all(color: iconBg.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: iconBg.withOpacity(0.2), blurRadius: 14),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: AppText.label(9,
                        color: context.c.inkDim, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.title(20,
                          color: valueColor, weight: FontWeight.w700)
                      .copyWith(
                    shadows: neonGlow(valueColor, blur: 8, opacity: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _AiPracticeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AiPracticeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: EdgeInsets.zero,
      glowColor: c.tertiaryContainer,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tertiaryFixedDim.withOpacity(0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonChip(
                  text: l.dashboard_aiModule,
                  icon: Icons.smart_toy_outlined,
                  color: c.tertiaryFixedDim,
                ),
                const SizedBox(height: 16),
                Text(
                  l.dashboard_aiTitle,
                  style: AppText.title(24,
                          color: c.tertiary, weight: FontWeight.w600)
                      .copyWith(
                    shadows: neonGlow(c.tertiary, blur: 8, opacity: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.dashboard_aiSubtitle,
                  style: AppText.body(13, color: c.inkMuted),
                ),
                const SizedBox(height: 18),
                NeonButton(
                  label: l.dashboard_aiStart,
                  icon: Icons.rocket_launch,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _DailyGoals extends StatelessWidget {
  final int due;
  final int total;
  final VoidCallback onTap;
  const _DailyGoals(
      {required this.due, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final progress =
        total == 0 ? 0.0 : ((total - due) / total).clamp(0.0, 1.0).toDouble();
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.dashboard_dailyGoals,
          style: AppText.title(20, color: c.ink, weight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        _GoalCard(
          language: l.dashboard_goalLanguage,
          subtitle: total == 0
              ? l.dashboard_goalLoading
              : due == 0
                  ? l.dashboard_goalAllCurrent
                  : l.words_review_due(due),
          progress: progress,
          percent: pct,
          color: c.primaryContainer,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String language;
  final String subtitle;
  final double progress;
  final int percent;
  final Color color;
  final VoidCallback onTap;
  const _GoalCard({
    required this.language,
    required this.subtitle,
    required this.progress,
    required this.percent,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: c.surfaceHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  l.dashboard_percentValue(percent),
                  style:
                      AppText.label(11, color: color, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language,
                    style: AppText.title(18,
                        color: c.primary, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle.toUpperCase(),
                    style: AppText.label(9,
                        color: c.inkDim, weight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.15), blurRadius: 10),
              ],
            ),
            child: Icon(Icons.play_arrow, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _LoadingDot extends StatelessWidget {
  const _LoadingDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.c.primaryContainer),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      borderColor: c.error.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppText.ink(13, color: c.error)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l.common_retry.toUpperCase(),
              style: AppText.label(10,
                  color: c.primaryContainer, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
