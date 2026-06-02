import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../l10n/generated/app_localizations.dart';
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
    final l = AppL10n.of(context);
    final c = context.c;
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));
    final progressAsync = ref.watch(lessonProgressMapProvider);
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          unit.title(locale),
          style: AppText.title(16,
              color: c.primaryContainer, weight: FontWeight.w700),
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
                        style: AppText.body(13, color: c.inkDim)),
                    const SizedBox(height: 16),
                    GhostButton(
                      label: l.common_retry,
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
                  final lesson = lessons[i];
                  final p = progress[lesson.id];
                  // İlk ders her zaman açık; sonraki ders, önceki tamamlanmadıysa kilitli
                  final prevLesson = i > 0 ? lessons[i - 1] : null;
                  final prevDone = prevLesson == null
                      ? true
                      : _isDone(progress[prevLesson.id]);
                  final isLocked = !prevDone;
                  return _LessonTile(
                    lesson: lesson,
                    progress: p,
                    locale: locale,
                    isLocked: isLocked,
                    onTap: isLocked
                        ? null
                        : () => context.push('/lessons/run/${lesson.id}',
                            extra: lesson),
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
    final c = context.c;
    final (icon, color) = _typeVisual(lesson.type, c);
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
              color: c.bgCard.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: stars >= 3
                    ? c.tertiary.withOpacity(0.5)
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
                            color: c.ink, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _typeChip(context, lesson.type, color),
                          const SizedBox(width: 6),
                          Text(
                            '+${lesson.xpReward} XP',
                            style: AppText.label(10,
                                color: c.tertiary, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Icon(Icons.lock_outline, color: c.inkDim, size: 18)
                else if (stars > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: c.tertiary,
                        size: 16,
                      );
                    }),
                  )
                else
                  Icon(Icons.chevron_right, color: c.inkDim),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(BuildContext context, LessonType type, Color color) {
    final l = AppL10n.of(context);
    String label;
    switch (type) {
      case LessonType.vocab:
        label = l.lesson_typeVocab;
        break;
      case LessonType.grammar:
        label = l.settings_grammar;
        break;
      case LessonType.conversation:
        label = l.lesson_typeSpeaking;
        break;
      case LessonType.listening:
        label = l.lesson_typeListening;
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

  (IconData, Color) _typeVisual(LessonType t, AppPalette c) {
    switch (t) {
      case LessonType.vocab:
        return (Icons.menu_book_outlined, c.primaryContainer);
      case LessonType.grammar:
        return (Icons.spellcheck_outlined, c.secondaryContainer);
      case LessonType.conversation:
        return (Icons.mic_none_outlined, c.tertiary);
      case LessonType.listening:
        return (Icons.headphones_outlined, c.success);
      case LessonType.quiz:
        return (Icons.quiz_outlined, c.warn);
    }
  }
}
