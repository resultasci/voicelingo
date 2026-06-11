/// Bir kurs = bir dil + CEFR seviye. ('en', 'A1') gibi.
class Course {
  final String id;
  final String language;
  final String level;
  final int orderIndex;
  const Course({
    required this.id,
    required this.language,
    required this.level,
    required this.orderIndex,
  });
  factory Course.fromMap(Map<String, dynamic> map) => Course(
        id: map['id'] as String,
        language: map['language'] as String,
        level: map['level'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
      );
}

/// Unit = kursun temalı bölümü (1 hafta ~ 4-6 ders).
class CourseUnit {
  final String id;
  final String courseId;
  final int orderIndex;
  final String titleTr;
  final String titleEn;
  final String? theme;
  final String? prerequisiteUnitId;

  const CourseUnit({
    required this.id,
    required this.courseId,
    required this.orderIndex,
    required this.titleTr,
    required this.titleEn,
    this.theme,
    this.prerequisiteUnitId,
  });

  String title(String locale) => locale == 'en' ? titleEn : titleTr;

  factory CourseUnit.fromMap(Map<String, dynamic> map) => CourseUnit(
        id: map['id'] as String,
        courseId: map['course_id'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
        titleTr: map['title_tr'] as String,
        titleEn: map['title_en'] as String,
        theme: map['theme'] as String?,
        prerequisiteUnitId: map['prerequisite_unit_id'] as String?,
      );
}

/// Lesson tipi — runner farklı widget'lar dispatch eder.
enum LessonType {
  vocab('vocab'),
  grammar('grammar'),
  conversation('conversation'),
  listening('listening'),
  quiz('quiz');

  final String code;
  const LessonType(this.code);

  static LessonType fromCode(String? c) => LessonType.values
      .firstWhere((t) => t.code == c, orElse: () => LessonType.vocab);
}

class Lesson {
  final String id;
  final String unitId;
  final int orderIndex;
  final LessonType type;
  final String titleTr;
  final String titleEn;
  final Map<String, dynamic> content;
  final int xpReward;

  const Lesson({
    required this.id,
    required this.unitId,
    required this.orderIndex,
    required this.type,
    required this.titleTr,
    required this.titleEn,
    required this.content,
    required this.xpReward,
  });

  String title(String locale) => locale == 'en' ? titleEn : titleTr;

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
        id: map['id'] as String,
        unitId: map['unit_id'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
        type: LessonType.fromCode(map['type'] as String?),
        titleTr: map['title_tr'] as String,
        titleEn: map['title_en'] as String,
        content: (map['content'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        xpReward: (map['xp_reward'] as num?)?.toInt() ?? 20,
      );
}

enum LessonStatus {
  locked('locked'),
  unlocked('unlocked'),
  inProgress('in_progress'),
  completed('completed'),
  mastered('mastered');

  final String code;
  const LessonStatus(this.code);

  static LessonStatus fromCode(String? c) => LessonStatus.values
      .firstWhere((s) => s.code == c, orElse: () => LessonStatus.unlocked);
}

class UserLessonProgress {
  final String userId;
  final String lessonId;
  final LessonStatus status;
  final int stars;
  final int? bestScore;
  final int attempts;
  final DateTime? lastAttemptAt;
  final DateTime? nextReviewAt;

  const UserLessonProgress({
    required this.userId,
    required this.lessonId,
    required this.status,
    required this.stars,
    required this.attempts,
    this.bestScore,
    this.lastAttemptAt,
    this.nextReviewAt,
  });

  bool get isReviewDue =>
      nextReviewAt != null &&
      nextReviewAt!.isBefore(DateTime.now()) &&
      status != LessonStatus.mastered;

  factory UserLessonProgress.fromMap(Map<String, dynamic> map) =>
      UserLessonProgress(
        userId: map['user_id'] as String,
        lessonId: map['lesson_id'] as String,
        status: LessonStatus.fromCode(map['status'] as String?),
        stars: (map['stars'] as num?)?.toInt() ?? 0,
        bestScore: (map['best_score'] as num?)?.toInt(),
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        lastAttemptAt: map['last_attempt_at'] != null
            ? DateTime.tryParse(map['last_attempt_at'] as String)
            : null,
        nextReviewAt: map['next_review_at'] != null
            ? DateTime.tryParse(map['next_review_at'] as String)
            : null,
      );

  /// Cache (Hive) serileştirmesi — `fromMap` ile tam round-trip uyumlu.
  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'lesson_id': lessonId,
        'status': status.code,
        'stars': stars,
        'best_score': bestScore,
        'attempts': attempts,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'next_review_at': nextReviewAt?.toIso8601String(),
      };
}
