import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../theme/app_theme.dart';

/// Horizontal scenario strip — surfaces scenarios on the empty Practice screen
/// so users discover them without hunting for the FAB.
class ScenarioStrip extends StatelessWidget {
  final ValueChanged<ScenarioModel> onPick;
  final VoidCallback onSeeAll;
  const ScenarioStrip(
      {super.key, required this.onPick, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: builtInScenarios.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == builtInScenarios.length) {
            return _AllScenariosTile(onTap: onSeeAll);
          }
          final s = builtInScenarios[i];
          return _ScenarioTile(scenario: s, onTap: () => onPick(s));
        },
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final ScenarioModel scenario;
  final VoidCallback onTap;
  const _ScenarioTile({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 168,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        glowColor: c.primaryContainer,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer.withOpacity(0.15),
                border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
              ),
              child: Icon(scenario.icon, color: c.primaryContainer, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              scenario.title,
              style:
                  AppText.title(14, color: c.primary, weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                scenario.description,
                style: AppText.body(11, color: c.inkMuted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllScenariosTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AllScenariosTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 132,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tertiaryFixedDim.withOpacity(0.15),
                border: Border.all(color: c.tertiaryFixedDim.withOpacity(0.4)),
              ),
              child: Icon(Icons.grid_view_rounded,
                  color: c.tertiaryFixedDim, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              AppL10n.of(context).conv_seeAll,
              style: AppText.label(11,
                  color: c.tertiaryFixedDim, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
