import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/scenario.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../conversation/screens/conversation_screen.dart';

class ScenarioPickerScreen extends StatelessWidget {
  const ScenarioPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    Semantics(
                      label: l.common_back,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: c.primaryContainer, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(l.nav_scenarios,
                          style: AppText.title(20,
                              color: c.primary, weight: FontWeight.w600)),
                    ),
                    Semantics(
                      label: l.scen_createWithAi,
                      button: true,
                      child: IconButton(
                        tooltip: l.scen_createWithAi,
                        icon: Icon(Icons.auto_awesome,
                            color: c.primaryContainer, size: 20),
                        onPressed: () => context.push('/scenario-builder'),
                      ),
                    ),
                    Semantics(
                      label: l.scen_allScenarios,
                      button: true,
                      child: IconButton(
                        tooltip: l.scen_allScenarios,
                        icon: Icon(Icons.grid_view_outlined,
                            color: c.primaryContainer, size: 20),
                        onPressed: () => context.push('/scenarios'),
                      ),
                    ),
                    Semantics(
                      label: l.convHist_freeChat,
                      button: true,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const ConversationScreen()),
                          );
                        },
                        child: Text(
                          l.scen_free,
                          style: AppText.label(11,
                              color: c.primaryContainer,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                  children: builtInScenarios.map((s) {
                    return _ScenarioCard(scenario: s);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final ScenarioModel scenario;
  const _ScenarioCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      glowColor: c.primaryContainer,
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => ConversationScreen(scenario: scenario)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primaryContainer.withOpacity(0.15),
              border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
            ),
            child: Icon(scenario.icon, color: c.primaryContainer, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.title,
            style: AppText.title(16, color: c.primary, weight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              scenario.description,
              style: AppText.body(12, color: c.inkMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.arrow_forward,
                  color: c.primaryContainer.withOpacity(0.7), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
