/// Gramer konu kataloğu satırı — Supabase `grammar_topics` tablosundan.
class GrammarTopic {
  final String id;
  final String level;
  final int orderIndex;
  final String code;
  final String titleTr;
  final String titleEn;
  final String? descriptionTr;
  final String? descriptionEn;
  final List<TopicExample> examples;
  final List<QuizQuestion> quiz;
  final int xpReward;

  const GrammarTopic({
    required this.id,
    required this.level,
    required this.orderIndex,
    required this.code,
    required this.titleTr,
    required this.titleEn,
    required this.examples,
    required this.quiz,
    this.descriptionTr,
    this.descriptionEn,
    this.xpReward = 30,
  });

  String title(String locale) => locale == 'en' ? titleEn : titleTr;
  String? description(String locale) =>
      locale == 'en' ? descriptionEn : descriptionTr;

  factory GrammarTopic.fromMap(Map<String, dynamic> map) => GrammarTopic(
        id: map['id'] as String,
        level: map['level'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
        code: map['code'] as String,
        titleTr: map['title_tr'] as String,
        titleEn: map['title_en'] as String,
        descriptionTr: map['description_tr'] as String?,
        descriptionEn: map['description_en'] as String?,
        examples: (map['examples'] as List? ?? const [])
            .map((e) => TopicExample.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        quiz: (map['quiz_questions'] as List? ?? const [])
            .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList(),
        xpReward: (map['xp_reward'] as num?)?.toInt() ?? 30,
      );

  /// Cache (Hive) serileştirmesi — `fromMap` ile tam round-trip uyumlu.
  Map<String, dynamic> toMap() => {
        'id': id,
        'level': level,
        'order_index': orderIndex,
        'code': code,
        'title_tr': titleTr,
        'title_en': titleEn,
        'description_tr': descriptionTr,
        'description_en': descriptionEn,
        'examples': examples.map((e) => e.toJson()).toList(),
        'quiz_questions': quiz.map((q) => q.toJson()).toList(),
        'xp_reward': xpReward,
      };
}

class TopicExample {
  final String en;
  final String tr;
  const TopicExample({required this.en, required this.tr});

  factory TopicExample.fromJson(Map<String, dynamic> json) => TopicExample(
      en: json['en'] as String? ?? '', tr: json['tr'] as String? ?? '');

  Map<String, dynamic> toJson() => {'en': en, 'tr': tr};
}

/// Quiz sorusu — `type` üç değerden biri: 'fill' (boşluk doldurma),
/// 'mc' (multiple choice), 'reorder' (kelime sırala — şimdilik desteklemiyoruz).
class QuizQuestion {
  final String type;
  final String promptEn;
  final String? promptTr;
  final List<String> options;
  final String answer;

  const QuizQuestion({
    required this.type,
    required this.promptEn,
    required this.answer,
    this.promptTr,
    this.options = const [],
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        type: json['type'] as String? ?? 'fill',
        promptEn: json['prompt_en'] as String? ?? '',
        promptTr: json['prompt_tr'] as String?,
        options:
            (json['options'] as List? ?? const []).whereType<String>().toList(),
        answer: json['answer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'prompt_en': promptEn,
        'prompt_tr': promptTr,
        'options': options,
        'answer': answer,
      };

  bool checkAnswer(String userInput) {
    return userInput.trim().toLowerCase() == answer.trim().toLowerCase();
  }
}

enum GrammarStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  mastered('mastered');

  final String code;
  const GrammarStatus(this.code);

  static GrammarStatus fromCode(String? c) => GrammarStatus.values
      .firstWhere((s) => s.code == c, orElse: () => GrammarStatus.notStarted);
}

class GrammarProgress {
  final String userId;
  final String topicId;
  final GrammarStatus status;
  final int? quizScore;
  final int attempts;
  final DateTime? completedAt;

  const GrammarProgress({
    required this.userId,
    required this.topicId,
    required this.status,
    required this.attempts,
    this.quizScore,
    this.completedAt,
  });

  factory GrammarProgress.fromMap(Map<String, dynamic> map) => GrammarProgress(
        userId: map['user_id'] as String,
        topicId: map['topic_id'] as String,
        status: GrammarStatus.fromCode(map['status'] as String?),
        quizScore: (map['quiz_score'] as num?)?.toInt(),
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        completedAt: map['completed_at'] != null
            ? DateTime.tryParse(map['completed_at'] as String)
            : null,
      );
}
