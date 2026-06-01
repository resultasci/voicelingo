import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/scenario.dart';
import '../../../theme/app_theme.dart';
import '../../conversation/screens/conversation_screen.dart';

class ScenarioPickerScreen extends StatelessWidget {
  const ScenarioPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Geri',
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.primaryContainer, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Senaryolar',
                          style: AppText.title(20,
                              color: AppColors.primary,
                              weight: FontWeight.w600)),
                    ),
                    Semantics(
                      label: 'AI ile senaryo yarat',
                      button: true,
                      child: IconButton(
                        tooltip: 'AI ile yarat',
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.primaryContainer, size: 20),
                        onPressed: () => context.push('/scenario-builder'),
                      ),
                    ),
                    Semantics(
                      label: 'Tüm senaryolar',
                      button: true,
                      child: IconButton(
                        tooltip: 'Tüm senaryolar',
                        icon: const Icon(Icons.grid_view_outlined,
                            color: AppColors.primaryContainer, size: 20),
                        onPressed: () => context.push('/scenarios'),
                      ),
                    ),
                    Semantics(
                      label: 'Serbest sohbet',
                      button: true,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const ConversationScreen()),
                          );
                        },
                        child: Text(
                          'Serbest',
                          style: AppText.label(11,
                              color: AppColors.primaryContainer,
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
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      glowColor: AppColors.primaryContainer,
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
              color: AppColors.primaryContainer.withOpacity(0.15),
              border: Border.all(
                  color: AppColors.primaryContainer.withOpacity(0.4)),
            ),
            child: Icon(scenario.icon,
                color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.title,
            style: AppText.title(16,
                color: AppColors.primary, weight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              scenario.description,
              style: AppText.body(12, color: AppColors.inkMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.arrow_forward,
                  color: AppColors.primaryContainer.withOpacity(0.7), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
