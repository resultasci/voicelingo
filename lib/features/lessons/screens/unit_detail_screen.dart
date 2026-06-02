import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/course.dart';
import '../services/courses_service.dart';

/// Bir unit'in ders listesi. Tap → lesson_runner.
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unit});
  final CourseUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));
    final progressAsync = ref.watch(lessonProgressMapProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          unit.title(locale),
          style: AppText.title(16,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: lessonsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(getErrorMessage(context, e),
                        textAlign: TextAlign.center,
                        style: AppText.body(13, color: AppColors.inkDim)),
                    const SizedBox(height: 16),
                    GhostButton(
                      label: locale == 'en' ? 'Retry' : 'Tekrar dene',
                      icon: Icons.refresh,
                      onTap: () =>
                          ref.invalidate(lessonsForUnitProvider(unit.id)),
                    ),
                  ],
                ),
              ),
            ),
            data: (lessons) {
              final progress = progressAsync.value ?? const {};
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: lessons.length,
                itemBuilder: (_, i) {
                  final l = lessons[i];
                  final p = progress[l.id];
                  // İlk ders her zaman açık; sonraki ders, önceki tamamlanmadıysa kilitli
                  final prevLesson = i > 0 ? lessons[i - 1] : null;
                  final prevDone = prevLesson == null
                      ? true
                      : _isDone(progress[prevLesson.id]);
                  final isLocked = !prevDone;
                  return _LessonTile(
                    lesson: l,
                    progress: p,
                    locale: locale,
                    isLocked: isLocked,
                    onTap: isLocked
                        ? null
                        : () => context.push('/lessons/run/${l.id}', extra: l),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isDone(UserLessonProgress? p) {
    if (p == null) return false;
    return p.status == LessonStatus.completed ||
        p.status == LessonStatus.mastered;
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.progress,
    required this.locale,
    required this.isLocked,
    required this.onTap,
  });
  final Lesson lesson;
  final UserLessonProgress? progress;
  final String locale;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeVisual(lesson.type);
    final stars = progress?.stars ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isLocked ? 0.45 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: stars >= 3
                    ? AppColors.tertiary.withOpacity(0.5)
                    : color.withOpacity(0.3),
                width: stars >= 3 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title(locale),
                        style: AppText.title(14,
                            color: AppColors.ink, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _typeChip(lesson.type, color, locale),
                          const SizedBox(width: 6),
                          Text(
                            '+${lesson.xpReward} XP',
                            style: AppText.label(10,
                                color: AppColors.tertiary,
                                weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  const Icon(Icons.lock_outline,
                      color: AppColors.inkDim, size: 18)
                else if (stars > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: AppColors.tertiary,
                        size: 16,
                      );
                    }),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.inkDim),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(LessonType type, Color color, String locale) {
    String label;
    switch (type) {
      case LessonType.vocab:
        label = locale == 'en' ? 'Vocab' : 'Kelime';
        break;
      case LessonType.grammar:
        label = locale == 'en' ? 'Grammar' : 'Gramer';
        break;
      case LessonType.conversation:
        label = locale == 'en' ? 'Speaking' : 'Konuşma';
        break;
      case LessonType.listening:
        label = locale == 'en' ? 'Listening' : 'Dinleme';
        break;
      case LessonType.quiz:
        label = 'Quiz';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppText.label(9, color: color, weight: FontWeight.w800),
      ),
    );
  }

  (IconData, Color) _typeVisual(LessonType t) {
    switch (t) {
      case LessonType.vocab:
        return (Icons.menu_book_outlined, AppColors.primaryContainer);
      case LessonType.grammar:
        return (Icons.spellcheck_outlined, AppColors.secondaryContainer);
      case LessonType.conversation:
        return (Icons.mic_none_outlined, AppColors.tertiary);
      case LessonType.listening:
        return (Icons.headphones_outlined, AppColors.success);
      case LessonType.quiz:
        return (Icons.quiz_outlined, AppColors.warn);
    }
  }
}
