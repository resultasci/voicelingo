import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/badge.dart';
import '../providers/gamification_providers.dart';

/// Kullanıcının kazandığı + kilitli rozetlerin galerisi.
/// 3-sütunlu grid; kilitli olanlar grayscale + lock icon.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final catalogAsync = ref.watch(badgesCatalogProvider);
    final earnedAsync = ref.watch(earnedBadgesProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.settings_badges,
          style: AppText.title(18,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
        foregroundColor: c.ink,
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getErrorMessage(context, e),
                      textAlign: TextAlign.center,
                      style: AppText.body(13, color: c.inkDim),
                    ),
                    const SizedBox(height: 16),
                    GhostButton(
                      label: l.common_retry,
                      icon: Icons.refresh,
                      onTap: () => ref.invalidate(badgesCatalogProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (catalog) {
              final earned = earnedAsync.value ?? const [];
              final earnedIds = earned.map((e) => e.badge.id).toSet();
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                itemCount: catalog.length,
                itemBuilder: (_, i) {
                  final badge = catalog[i];
                  final isEarned = earnedIds.contains(badge.id);
                  return _BadgeTile(
                    badge: badge,
                    earned: isEarned,
                    locale: locale,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.earned,
    required this.locale,
  });
  final LearningBadge badge;
  final bool earned;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = earned ? c.primaryContainer : c.inkDim.withOpacity(0.4);
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard.withOpacity(earned ? 0.8 : 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
              border: Border.all(color: color.withOpacity(0.6)),
            ),
            child: Icon(
              _resolveIcon(badge.icon),
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.displayName(locale),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(11, color: color, weight: FontWeight.w700),
          ),
          if (!earned) ...[
            const SizedBox(height: 4),
            Icon(Icons.lock_outline,
                size: 14, color: c.inkDim.withOpacity(0.6)),
          ],
        ],
      ),
    );
  }

  IconData _resolveIcon(String? code) {
    switch (code) {
      case 'flame':
        return Icons.local_fire_department;
      case 'book':
        return Icons.menu_book;
      case 'mic':
        return Icons.mic;
      case 'star':
        return Icons.star;
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'moon':
        return Icons.nightlight_round;
      case 'theater_comedy':
        return Icons.theater_comedy_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}
