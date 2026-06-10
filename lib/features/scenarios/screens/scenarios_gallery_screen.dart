import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../conversation/screens/conversation_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../models/dynamic_scenario.dart';
import '../services/scenarios_service.dart';

/// Tüm görülebilir senaryolar (sistem + kullanıcının kendi).
/// Tap → conversation_screen.dart'a karakter prompt + scenario context ile push.
class ScenariosGalleryScreen extends ConsumerWidget {
  const ScenariosGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final async = ref.watch(visibleScenariosProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          l.nav_scenarios,
          style: AppText.title(18,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l.scen_newScenario,
            icon: Icon(Icons.auto_awesome, color: c.primaryContainer),
            onPressed: () => context.push('/scenario-builder'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primaryContainer,
        foregroundColor: c.onPrimary,
        onPressed: () => context.push('/scenario-builder'),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l.scen_create),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getErrorMessage(context, e),
                      style: AppText.body(13, color: c.inkDim),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GhostButton(
                      label: l.common_retry,
                      icon: Icons.refresh,
                      onTap: () => ref.invalidate(visibleScenariosProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    l.scen_empty,
                    style: AppText.body(13, color: c.inkDim),
                  ),
                );
              }
              final mine = list.where((s) => !s.isSystem).toList();
              final system = list.where((s) => s.isSystem).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                children: [
                  if (mine.isNotEmpty) ...[
                    _SectionHeader(title: l.scen_yours),
                    for (final s in mine)
                      _ScenarioTile(scenario: s, locale: locale),
                    const SizedBox(height: 16),
                  ],
                  if (system.isNotEmpty) ...[
                    _SectionHeader(title: l.scen_builtIn),
                    for (final s in system)
                      _ScenarioTile(scenario: s, locale: locale),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: AppText.label(11,
            color: context.c.primaryContainer, weight: FontWeight.w800),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario, required this.locale});
  final DynamicScenario scenario;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final model = scenario.toScenarioModel();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationScreen(
                scenario: model,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.inkDim.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primaryContainer.withOpacity(0.16),
                  border:
                      Border.all(color: c.primaryContainer.withOpacity(0.5)),
                ),
                child: Icon(model.icon, color: c.primaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title(locale),
                      style: AppText.title(14,
                          color: c.ink, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.tertiary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scenario.difficulty.label(locale),
                            style: AppText.label(9,
                                color: c.tertiary, weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.scen_turnsCount(scenario.estimatedTurns),
                          style: AppText.label(10, color: c.inkDim),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}
