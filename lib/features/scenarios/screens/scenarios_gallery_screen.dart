import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/locale_provider.dart';
import '../../conversation/screens/conversation_screen.dart';
import '../../../theme/app_theme.dart';
import '../models/dynamic_scenario.dart';
import '../services/scenarios_service.dart';

/// Tüm görülebilir senaryolar (sistem + kullanıcının kendi).
/// Tap → conversation_screen.dart'a karakter prompt + scenario context ile push.
class ScenariosGalleryScreen extends ConsumerWidget {
  const ScenariosGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(visibleScenariosProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Scenarios' : 'Senaryolar',
          style: AppText.title(18,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: locale == 'en' ? 'New scenario' : 'Yeni senaryo',
            icon: const Icon(Icons.auto_awesome,
                color: AppColors.primaryContainer),
            onPressed: () => context.push('/scenario-builder'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => context.push('/scenario-builder'),
        icon: const Icon(Icons.add, size: 18),
        label: Text(locale == 'en' ? 'Create' : 'Yarat'),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  e.toString(),
                  style: AppText.body(13, color: AppColors.inkDim),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    locale == 'en'
                        ? 'No scenarios yet. Tap Create to generate one.'
                        : 'Henüz senaryo yok. Yarat butonuna bas.',
                    style: AppText.body(13, color: AppColors.inkDim),
                  ),
                );
              }
              final mine = list.where((s) => !s.isSystem).toList();
              final system = list.where((s) => s.isSystem).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                children: [
                  if (mine.isNotEmpty) ...[
                    _SectionHeader(
                        title:
                            locale == 'en' ? 'Yours' : 'Senin yarattıkların'),
                    for (final s in mine)
                      _ScenarioTile(scenario: s, locale: locale),
                    const SizedBox(height: 16),
                  ],
                  if (system.isNotEmpty) ...[
                    _SectionHeader(
                        title:
                            locale == 'en' ? 'Built-in' : 'Hazır senaryolar'),
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
            color: AppColors.primaryContainer, weight: FontWeight.w800),
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
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inkDim.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withOpacity(0.16),
                  border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.5)),
                ),
                child: Icon(model.icon,
                    color: AppColors.primaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title(locale),
                      style: AppText.title(14,
                          color: AppColors.ink, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scenario.difficulty.label(locale),
                            style: AppText.label(9,
                                color: AppColors.tertiary,
                                weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '~${scenario.estimatedTurns} ${locale == 'en' ? 'turns' : 'tur'}',
                          style: AppText.label(10, color: AppColors.inkDim),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}
