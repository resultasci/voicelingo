import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../services/activity_service.dart';
import '../widgets/activity_heatmap.dart';

/// İlerleme dashboard'u: heatmap + mastery + top errors.
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final dailyXpAsync = ref.watch(dailyXpProvider(90));
    final masteryAsync = ref.watch(masterySummaryProvider);
    final topErrorsAsync = ref.watch(topErrorsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Progress' : 'İlerleme',
          style: AppText.title(18,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _SectionTitle(
                  title: locale == 'en' ? 'Last 90 days' : 'Son 90 gün'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dailyXpAsync.when(
                      loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        e.toString(),
                        style: AppText.body(12, color: AppColors.inkDim),
                      ),
                      data: (xp) => ActivityHeatmap(
                        dailyXp: xp,
                        days: 90,
                        onTap: (day, xpVal) =>
                            _showDayDetail(context, day, xpVal, locale),
                      ),
                    ),
                    const SizedBox(height: 10),
                    HeatmapLegend(locale: locale),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: locale == 'en' ? 'Mastery' : 'Ustalaşma'),
              const SizedBox(height: 10),
              masteryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  e.toString(),
                  style: AppText.body(12, color: AppColors.inkDim),
                ),
                data: (s) => s == null
                    ? Text(
                        locale == 'en' ? 'No data yet.' : 'Henüz veri yok.',
                        style: AppText.body(12, color: AppColors.inkDim),
                      )
                    : Column(
                        children: [
                          _MasteryRow(
                            label: locale == 'en' ? 'Words' : 'Kelimeler',
                            color: AppColors.primaryContainer,
                            done: s.wordsMastered,
                            total: s.wordsTotal,
                            ratio: s.wordsRatio,
                          ),
                          const SizedBox(height: 10),
                          _MasteryRow(
                            label: locale == 'en' ? 'Grammar' : 'Gramer',
                            color: AppColors.secondaryContainer,
                            done: s.grammarCompleted,
                            total: s.grammarTotal,
                            ratio: s.grammarRatio,
                          ),
                          const SizedBox(height: 10),
                          _MasteryRow(
                            label: locale == 'en' ? 'Lessons' : 'Dersler',
                            color: AppColors.tertiary,
                            done: s.lessonsCompleted,
                            total: s.lessonsTotal,
                            ratio: s.lessonsRatio,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                  title: locale == 'en'
                      ? 'Top mistakes (30 days)'
                      : 'En sık hatalar (30 gün)'),
              const SizedBox(height: 10),
              topErrorsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (errors) {
                  if (errors.isEmpty) {
                    return _Card(
                      child: Text(
                        locale == 'en'
                            ? 'No mistakes recorded yet — keep practicing!'
                            : 'Henüz hata kaydı yok — pratik yapmaya devam!',
                        style: AppText.body(13, color: AppColors.inkDim),
                      ),
                    );
                  }
                  return _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in errors)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.type,
                                    style:
                                        AppText.body(13, color: AppColors.ink),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${e.occurrences}x',
                                    style: AppText.label(10,
                                        color: AppColors.error,
                                        weight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetail(
      BuildContext context, DateTime day, int xp, String locale) {
    final fmt =
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        duration: const Duration(seconds: 2),
        content: Text(
          '$fmt — $xp XP',
          style: AppText.ink(13, color: AppColors.primaryContainer),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppText.label(11,
          color: AppColors.primaryContainer, weight: FontWeight.w800),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkDim.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({
    required this.label,
    required this.color,
    required this.done,
    required this.total,
    required this.ratio,
  });
  final String label;
  final Color color;
  final int done;
  final int total;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.title(14,
                      color: AppColors.ink, weight: FontWeight.w700),
                ),
              ),
              Text(
                '$done / $total',
                style: AppText.label(12, color: color, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.inkDim.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }
}
