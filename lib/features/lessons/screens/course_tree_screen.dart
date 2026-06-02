import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/course.dart';
import '../services/courses_service.dart';

/// Tüm kurslar + ilk kursun unit ağacı.
/// MVP: A1 kursu (tek kurs); ileride CEFR seçici eklenebilir.
class CourseTreeScreen extends ConsumerWidget {
  const CourseTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Course' : 'Ders Yolu',
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
              ref.invalidate(coursesListProvider);
              ref.invalidate(lessonProgressMapProvider);
              await ref.read(coursesListProvider.future);
            },
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(context, e, locale),
              data: (courses) {
                if (courses.isEmpty) {
                  return _emptyView(locale);
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

  Widget _errorView(BuildContext context, Object e, String locale) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(getErrorMessage(context, e),
                style: AppText.body(14, color: AppColors.inkDim),
                textAlign: TextAlign.center),
          ),
        ],
      );

  Widget _emptyView(String locale) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              locale == 'en'
                  ? 'No course yet. Make sure the migration is applied.'
                  : 'Henüz kurs yok. Veritabanında derslerin kurulu olduğundan emin ol.',
              style: AppText.body(14, color: AppColors.inkDim),
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
    final unitsAsync = ref.watch(unitsForCourseProvider(course.id));
    final progressAsync = ref.watch(lessonProgressMapProvider);

    return unitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(getErrorMessage(context, e),
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.inkDim)),
        ),
      ),
      data: (units) {
        if (units.isEmpty) {
          return Center(
            child: Text(
              locale == 'en' ? 'No units yet.' : 'Henüz ünite yok.',
              style: AppText.body(13, color: AppColors.inkDim),
            ),
          );
        }
        final progress = progressAsync.value ?? const {};
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Course header
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryContainer.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryContainer.withOpacity(0.5)),
                    ),
                    child: Text(
                      course.level,
                      style: AppText.label(11,
                          color: AppColors.primaryContainer,
                          weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    locale == 'en' ? 'English Course' : 'İngilizce Kursu',
                    style: AppText.title(15,
                        color: AppColors.ink, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < units.length; i++)
              _UnitTile(
                unit: units[i],
                index: i,
                allUnits: units,
                progressMap: progress,
                locale: locale,
              ),

            const SizedBox(height: 24),
            _CustomScenarioCard(locale: locale),
          ],
        );
      },
    );
  }
}

class _UnitTile extends ConsumerWidget {
  const _UnitTile({
    required this.unit,
    required this.index,
    required this.allUnits,
    required this.progressMap,
    required this.locale,
  });

  final CourseUnit unit;
  final int index;
  final List<CourseUnit> allUnits;
  final Map<String, UserLessonProgress> progressMap;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));

    return lessonsAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
      data: (lessons) {
        final allCompleted = lessons.isNotEmpty &&
            lessons.every((l) {
              final p = progressMap[l.id];
              return p?.status == LessonStatus.completed ||
                  p?.status == LessonStatus.mastered;
            });
        final completedCount = lessons.where((l) {
          final p = progressMap[l.id];
          return p?.status == LessonStatus.completed ||
              p?.status == LessonStatus.mastered;
        }).length;
        final progressRatio =
            lessons.isEmpty ? 0.0 : completedCount / lessons.length;

        // Unlocked? prerequisite kontrolü
        final svc = ref.read(coursesServiceProvider);
        final lessonsByUnit = {unit.id: lessons};
        final unlocked =
            svc.isUnitUnlocked(unit, allUnits, progressMap, lessonsByUnit);

        // prerequisite başka unit ise — onun ders listesini çekemediğimiz
        // için bu UI tarafında varsayım: önceki unit tamamlanmadıysa kilitli.
        final prevUnit = index > 0 ? allUnits[index - 1] : null;
        bool prevDone = true;
        if (prevUnit != null) {
          // Çağrı zinciri yok; ref.read ile lessons çekmek async olur.
          // Pragmatik: önceki unit'in lesson'larını da prefetch için
          // burada watch ediyoruz.
          final prevLessonsAsync =
              ref.watch(lessonsForUnitProvider(prevUnit.id));
          prevLessonsAsync.whenData((prev) {
            prevDone = prev.every((l) {
              final p = progressMap[l.id];
              return p?.status == LessonStatus.completed ||
                  p?.status == LessonStatus.mastered;
            });
          });
        }
        final isLocked = !unlocked && !prevDone && index > 0;

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
                  color: AppColors.bgCard.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: allCompleted
                        ? AppColors.tertiary.withOpacity(0.5)
                        : isLocked
                            ? AppColors.inkDim.withOpacity(0.2)
                            : AppColors.primaryContainer.withOpacity(0.4),
                    width: allCompleted ? 2 : 1,
                  ),
                  boxShadow: allCompleted
                      ? [
                          BoxShadow(
                            color: AppColors.tertiary.withOpacity(0.2),
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
                                ? AppColors.tertiary.withOpacity(0.2)
                                : AppColors.primaryContainer.withOpacity(0.18),
                            border: Border.all(
                                color: allCompleted
                                    ? AppColors.tertiary
                                    : AppColors.primaryContainer
                                        .withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: AppText.title(15,
                                color: allCompleted
                                    ? AppColors.tertiary
                                    : AppColors.primaryContainer,
                                weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            unit.title(locale),
                            style: AppText.title(15,
                                color: AppColors.ink, weight: FontWeight.w700),
                          ),
                        ),
                        if (isLocked)
                          const Icon(Icons.lock_outline,
                              color: AppColors.inkDim, size: 18)
                        else if (allCompleted)
                          const Icon(Icons.workspace_premium,
                              color: AppColors.tertiary, size: 22)
                        else
                          const Icon(Icons.chevron_right,
                              color: AppColors.inkDim),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 5,
                      backgroundColor: AppColors.inkDim.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(
                        allCompleted
                            ? AppColors.tertiary
                            : AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$completedCount / ${lessons.length} ${locale == 'en' ? "lessons" : "ders"}',
                      style: AppText.label(10, color: AppColors.inkDim),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomScenarioCard extends StatelessWidget {
  const _CustomScenarioCard({required this.locale});
  final String locale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scenario-builder'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryContainer.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'en'
                        ? 'Create Custom Scenario'
                        : 'Özel Senaryo Oluştur',
                    style: AppText.title(15,
                        color: AppColors.ink, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'en'
                        ? 'Practice with AI on any topic you want.'
                        : 'Yapay zeka ile dilediğin konuda pratik yap.',
                    style: AppText.body(11, color: AppColors.inkDim),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.primaryContainer),
          ],
        ),
      ),
    );
  }
}
