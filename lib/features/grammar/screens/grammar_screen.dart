import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/grammar_topic.dart';
import '../services/grammar_service.dart';

/// Gramer konuları ekranı. CEFR seviyesine göre gruplanmış liste.
class GrammarScreen extends ConsumerWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(grammarTopicsProvider);
    final progressAsync = ref.watch(grammarProgressProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Grammar' : 'Gramer',
          style: AppText.title(18,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryContainer,
            backgroundColor: AppColors.bgCard,
            onRefresh: () async {
              ref.invalidate(grammarTopicsProvider);
              ref.invalidate(grammarProgressProvider);
              await ref.read(grammarTopicsProvider.future);
            },
            child: topicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      getErrorMessage(context, e),
                      style: AppText.body(14, color: AppColors.inkDim),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              data: (topics) {
                final byLevel = <String, List<GrammarTopic>>{};
                for (final t in topics) {
                  byLevel.putIfAbsent(t.level, () => []).add(t);
                }
                final levels = byLevel.keys.toList()..sort();
                if (topics.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          locale == 'en'
                              ? 'No grammar topics yet. Make sure you applied the migration.'
                              : 'Henüz gramer konusu yok. Veritabanı yenilemesi (migration) uygulandı mı kontrol et.',
                          style: AppText.body(14, color: AppColors.inkDim),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
                final progress = progressAsync.value ?? const {};
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    for (final lvl in levels) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryContainer
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                lvl,
                                style: AppText.label(11,
                                    color: AppColors.primaryContainer,
                                    weight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              locale == 'en' ? 'Level' : 'Seviye',
                              style: AppText.label(11,
                                  color: AppColors.inkDim,
                                  weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      for (final t in byLevel[lvl]!)
                        _TopicTile(
                          topic: t,
                          progress: progress[t.id],
                          locale: locale,
                          onTap: () =>
                              context.push('/grammar/${t.id}', extra: t),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.progress,
    required this.locale,
    required this.onTap,
  });
  final GrammarTopic topic;
  final GrammarProgress? progress;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = progress?.status ?? GrammarStatus.notStarted;
    final (icon, color) = _statusVisual(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title(locale),
                      style: AppText.title(14,
                          color: AppColors.ink, weight: FontWeight.w700),
                    ),
                    if (progress?.quizScore != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${locale == 'en' ? 'Best score' : 'En iyi skor'}: ${progress!.quizScore}',
                        style: AppText.label(10, color: AppColors.inkDim),
                      ),
                    ],
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

  (IconData, Color) _statusVisual(GrammarStatus s) {
    switch (s) {
      case GrammarStatus.mastered:
        return (Icons.workspace_premium, AppColors.tertiary);
      case GrammarStatus.completed:
        return (Icons.check_circle, AppColors.success);
      case GrammarStatus.inProgress:
        return (Icons.timelapse, AppColors.secondaryContainer);
      case GrammarStatus.notStarted:
        return (Icons.menu_book_outlined, AppColors.primaryContainer);
    }
  }
}
