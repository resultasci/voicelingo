import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/words/providers/words_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringRotation;

  @override
  void initState() {
    super.initState();
    _ringRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _ringRotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final profileAsync = ref.watch(profileProvider);
    final wordsAsync = ref.watch(wordsProvider);
    final email = ref.read(authServiceProvider).currentUser?.email ?? '';

    return profileAsync.when(
      data: (profile) {
        final username = profile?.username ?? l.profile_defaultName;
        final level = profile?.level ?? 1;
        final xp = profile?.xp ?? 0;
        final streak = profile?.streakDays ?? 0;
        final words = wordsAsync.value ?? const [];
        final wordCount = words.length;

        final reviewed = words.where((w) => w.repetitions > 0).toList();
        final correctRate = reviewed.isEmpty
            ? 0.0
            : reviewed.where((w) => w.repetitions >= 3).length /
                reviewed.length;
        final fluency = (correctRate * 50 +
                (streak.clamp(0, 30) / 30) * 30 +
                (xp.clamp(0, 2000) / 2000) * 20)
            .clamp(0, 100)
            .round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            _Header(
              username: username,
              level: level,
              email: email,
              ringController: _ringRotation,
            ),
            const SizedBox(height: 32),
            _StatsRow(
              streak: streak,
              wordCount: wordCount,
              fluency: fluency,
            ),
            const SizedBox(height: 32),
            _BadgeSection(
              wordCount: wordCount,
              level: level,
              streak: streak,
            ),
            const SizedBox(height: 32),
            _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
          ],
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: c.primaryContainer),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.dashboard_profileLoadError,
                  style: AppText.body(14, color: c.error)),
              const SizedBox(height: 12),
              GhostButton(
                label: l.common_retry,
                icon: Icons.refresh,
                onTap: () => ref.invalidate(profileProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final c = context.c;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: c.error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: c.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SectionLabel(l.auth_signOut, color: c.error),
              const SizedBox(height: 14),
              Text(l.settings_signOutConfirm,
                  style: AppText.title(20,
                      color: c.primary, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(l.profile_signOutWarning,
                  style: AppText.body(13, color: c.inkMuted)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: l.common_cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: l.settings_disconnect,
                      icon: Icons.logout,
                      color: c.error,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }
}

// =============================================================================
class _Header extends StatelessWidget {
  final String username;
  final int level;
  final String email;
  final AnimationController ringController;
  const _Header({
    required this.username,
    required this.level,
    required this.email,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: ringController,
                builder: (_, __) => Transform.rotate(
                  angle: ringController.value * 6.28,
                  child: CustomPaint(
                    painter: _DashedRingPainter(
                        color: c.primaryContainer.withOpacity(0.55)),
                    size: const Size(140, 140),
                  ),
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceHigh,
                  border: Border.all(
                      color: c.primaryContainer.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: c.primaryContainer.withOpacity(0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppText.hero(46,
                          color: c.primaryContainer, weight: FontWeight.w700)
                      .copyWith(
                    shadows:
                        neonGlow(c.primaryContainer, blur: 14, opacity: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          username.toUpperCase(),
          style:
              AppText.hero(28, color: c.ink, weight: FontWeight.w700).copyWith(
            letterSpacing: 1.6,
            shadows: neonGlow(Colors.white, blur: 8, opacity: 0.2),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: c.primaryContainer, size: 16),
            const SizedBox(width: 6),
            Text(
              l.profile_levelTitle(level),
              style:
                  AppText.label(11, color: c.inkDim, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppText.code(11, color: c.inkDim),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashCount = 32;
    final radius = size.width / 2 - 4;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final start = (i / dashCount) * 6.28;
      final end = ((i + 1) / dashCount) * 6.28;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, end - start, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

// =============================================================================
class _StatsRow extends StatelessWidget {
  final int streak;
  final int wordCount;
  final int fluency;
  const _StatsRow({
    required this.streak,
    required this.wordCount,
    required this.fluency,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department,
            iconColor: c.secondaryContainer,
            value: streak.toString(),
            label: l.profile_dailyStreak,
            stripColor: c.secondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.translate,
            iconColor: c.primaryContainer,
            value: _fmt(wordCount),
            label: l.nav_words,
            stripColor: c.primaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: l.profile_fluencyTooltip,
            triggerMode: TooltipTriggerMode.tap,
            preferBelow: true,
            child: _StatTile(
              icon: Icons.psychology,
              iconColor: c.tertiaryFixedDim,
              value: l.dashboard_percentValue(fluency),
              label: l.profile_fluency,
              stripColor: c.tertiaryFixedDim,
            ),
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color stripColor;
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.stripColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GlassPanel(
      padding: EdgeInsets.zero,
      glowColor: stripColor,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [stripColor, stripColor.withOpacity(0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(height: 12),
                FittedBox(
                  child: Text(
                    value,
                    style:
                        AppText.hero(28, color: c.ink, weight: FontWeight.w700)
                            .copyWith(
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: AppText.label(8,
                        color: c.inkDim, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _BadgeSection extends StatelessWidget {
  final int wordCount;
  final int level;
  final int streak;
  const _BadgeSection({
    required this.wordCount,
    required this.level,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final badges = <_Badge>[
      _Badge(
        icon: Icons.rocket_launch,
        title: l.profile_badge1Title,
        sub: l.profile_badge1Sub,
        unlocked: wordCount >= 100,
        color: c.primaryContainer,
      ),
      _Badge(
        icon: Icons.public,
        title: l.profile_badge2Title,
        sub: l.profile_badge2Sub,
        unlocked: level >= 5,
        color: c.secondaryContainer,
      ),
      _Badge(
        icon: Icons.local_fire_department,
        title: l.profile_badge3Title,
        sub: l.profile_badge3Sub,
        unlocked: streak >= 7,
        color: c.secondary,
      ),
      _Badge(
        icon: Icons.workspace_premium,
        title: l.profile_badge4Title,
        sub: l.profile_badge4Sub,
        unlocked: level >= 20,
        color: c.tertiaryFixedDim,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium, color: c.primaryContainer, size: 22),
            const SizedBox(width: 10),
            Text(
              l.profile_badgesTitle,
              style: AppText.title(18, color: c.ink, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: badges.map((b) => _BadgeTile(badge: b)).toList(),
        ),
      ],
    );
  }
}

class _Badge {
  final IconData icon;
  final String title;
  final String sub;
  final bool unlocked;
  final Color color;
  _Badge({
    required this.icon,
    required this.title,
    required this.sub,
    required this.unlocked,
    required this.color,
  });
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.45,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        glowColor: badge.unlocked ? badge.color : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceHigh,
                border: Border.all(
                  color: badge.unlocked
                      ? badge.color.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                ),
                boxShadow: badge.unlocked
                    ? [
                        BoxShadow(
                            color: badge.color.withOpacity(0.25),
                            blurRadius: 16),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                badge.unlocked ? badge.icon : Icons.lock_outline,
                color: badge.unlocked ? badge.color : c.inkDim,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title,
              style: AppText.label(11,
                  color: badge.unlocked ? c.ink : c.inkDim,
                  weight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              badge.unlocked ? badge.sub : l.profile_locked,
              style: AppText.code(9, color: c.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GhostButton(
        label: AppL10n.of(context).profile_disconnect,
        icon: Icons.logout,
        color: context.c.error,
        onTap: onTap,
      ),
    );
  }
}
