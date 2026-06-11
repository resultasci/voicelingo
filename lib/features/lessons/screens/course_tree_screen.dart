import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/course.dart';
import '../services/courses_service.dart';

/// Tüm kurslar + ilk kursun unit ağacı.
/// MVP: A1 kursu (tek kurs); ileride CEFR seçici eklenebilir.
class CourseTreeScreen extends ConsumerWidget {
  const CourseTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final coursesAsync = ref.watch(coursesListProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          l.lesson_courseTitle,
          style: AppText.title(18,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: c.primaryContainer,
            backgroundColor: c.bgCard,
            onRefresh: () async {
              // Hive girdisi düşmeden provider invalidate'i bayat satırı
              // yeniden servis eder.
              await ref.read(coursesServiceProvider).invalidateProgressCache();
              ref.invalidate(coursesListProvider);
              ref.invalidate(lessonProgressMapProvider);
              await ref.read(coursesListProvider.future);
            },
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(context, e),
              data: (courses) {
                if (courses.isEmpty) {
                  return _emptyView(context);
                }
                // MVP: ilk kursu otomatik aç (A1).
                final course = courses.first;
                return _CourseUnits(course: course, locale: locale);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, Object e) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(getErrorMessage(context, e),
                style: AppText.body(14, color: context.c.inkDim),
                textAlign: TextAlign.center),
          ),
        ],
      );

  Widget _emptyView(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppL10n.of(context).lesson_emptyCourse,
              style: AppText.body(14, color: context.c.inkDim),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
}

class _CourseUnits extends ConsumerWidget {
  const _CourseUnits({required this.course, required this.locale});
  final Course course;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final unitsAsync = ref.watch(unitsForCourseProvider(course.id));
    final progressAsync = ref.watch(lessonProgressMapProvider);
    // Tüm ünitelerin ders haritası tek seferde — tile başına ayrı provider
    // izlemek hem O(n) watcher yaratıyordu hem de build sırasında whenData
    // ile state okuma riskine yol açıyordu.
    final lessonsMapAsync = ref.watch(unitLessonsMapProvider(course.id));

    return unitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(getErrorMessage(context, e),
              textAlign: TextAlign.center,
              style: AppText.body(13, color: c.inkDim)),
        ),
      ),
      data: (units) {
        if (units.isEmpty) {
          return Center(
            child: Text(
              l.lesson_noUnits,
              style: AppText.body(13, color: c.inkDim),
            ),
          );
        }
        final progress = progressAsync.value ?? const {};
        final lessonsByUnit =
            lessonsMapAsync.value ?? const <String, List<Lesson>>{};
        final svc = ref.read(coursesServiceProvider);

        bool lessonDone(Lesson lesson) {
          final p = progress[lesson.id];
          return p?.status == LessonStatus.completed ||
              p?.status == LessonStatus.mastered;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Course header
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.bgCard.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.primaryContainer.withOpacity(0.5)),
                    ),
                    child: Text(
                      course.level,
                      style: AppText.label(11,
                          color: c.primaryContainer, weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.lesson_englishCourse,
                    style: AppText.title(15,
                        color: c.ink, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            // Unlock/ilerleme hesapları burada tek geçişte yapılır; tile'lar
            // saf değer alır ve progress güncellemesinde yalnız değeri
            // değişenler yeniden boyanır.
            for (var i = 0; i < units.length; i++)
              () {
                final unit = units[i];
                final lessons = lessonsByUnit[unit.id] ?? const <Lesson>[];
                final completedCount = lessons.where(lessonDone).length;
                final unlocked =
                    svc.isUnitUnlocked(unit, units, progress, lessonsByUnit);
                final prevLessons = i > 0
                    ? (lessonsByUnit[units[i - 1].id] ?? const <Lesson>[])
                    : const <Lesson>[];
                final prevDone = prevLessons.every(lessonDone);
                return _UnitTile(
                  unit: unit,
                  index: i,
                  locale: locale,
                  completedCount: completedCount,
                  lessonCount: lessons.length,
                  isLocked: !unlocked && !prevDone && i > 0,
                );
              }(),
            const SizedBox(height: 24),
            const _CustomScenarioCard(),
          ],
        );
      },
    );
  }
}

/// Saf değer alan tile — provider izlemez; unlock/ilerleme hesapları
/// [_CourseUnits]'ta tek geçişte yapılır (tam lessonsByUnit haritasıyla,
/// eski tek-girdili workaround yerine).
class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.index,
    required this.locale,
    required this.completedCount,
    required this.lessonCount,
    required this.isLocked,
  });

  final CourseUnit unit;
  final int index;
  final String locale;
  final int completedCount;
  final int lessonCount;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final allCompleted = lessonCount > 0 && completedCount == lessonCount;
    final progressRatio = lessonCount == 0 ? 0.0 : completedCount / lessonCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isLocked
            ? null
            : () => context.push('/lessons/unit/${unit.id}', extra: unit),
        borderRadius: BorderRadius.circular(18),
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.bgCard.withOpacity(0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: allCompleted
                    ? c.tertiary.withOpacity(0.5)
                    : isLocked
                        ? c.inkDim.withOpacity(0.2)
                        : c.primaryContainer.withOpacity(0.4),
                width: allCompleted ? 2 : 1,
              ),
              boxShadow: allCompleted
                  ? [
                      BoxShadow(
                        color: c.tertiary.withOpacity(0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: allCompleted
                            ? c.tertiary.withOpacity(0.2)
                            : c.primaryContainer.withOpacity(0.18),
                        border: Border.all(
                            color: allCompleted
                                ? c.tertiary
                                : c.primaryContainer.withOpacity(0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: AppText.title(15,
                            color:
                                allCompleted ? c.tertiary : c.primaryContainer,
                            weight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        unit.title(locale),
                        style: AppText.title(15,
                            color: c.ink, weight: FontWeight.w700),
                      ),
                    ),
                    if (isLocked)
                      Icon(Icons.lock_outline, color: c.inkDim, size: 18)
                    else if (allCompleted)
                      Icon(Icons.workspace_premium, color: c.tertiary, size: 22)
                    else
                      Icon(Icons.chevron_right, color: c.inkDim),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progressRatio,
                  minHeight: 5,
                  backgroundColor: c.inkDim.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(
                    allCompleted ? c.tertiary : c.primaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedCount / $lessonCount ${l.lesson_lessonsSuffix}',
                  style: AppText.label(10, color: c.inkDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomScenarioCard extends StatelessWidget {
  const _CustomScenarioCard();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GestureDetector(
      onTap: () => context.push('/scenario-builder'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.primaryContainer.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.primaryContainer.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: c.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.lesson_customScenarioTitle,
                    style: AppText.title(15,
                        color: c.ink, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.lesson_customScenarioBody,
                    style: AppText.body(11, color: c.inkDim),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: c.primaryContainer),
          ],
        ),
      ),
    );
  }
}
