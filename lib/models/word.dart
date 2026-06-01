import 'dart:math';

class Word {
  final String id;
  final String userId;
  final String word;
  final String translation;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final DateTime createdAt;
  final String? ipa;
  final String? exampleSentence;

  const Word({
    required this.id,
    required this.userId,
    required this.word,
    required this.translation,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    required this.nextReview,
    required this.createdAt,
    this.ipa,
    this.exampleSentence,
  });

  bool get isDue => DateTime.now().isAfter(nextReview);

  /// Hive cache yazımı için. Supabase row formatıyla aynı anahtarları kullan,
  /// böylece fromMap simetri ile geri okuyabilir.
  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'word': word,
        'translation': translation,
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'next_review': nextReview.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (ipa != null) 'ipa': ipa,
        if (exampleSentence != null) 'example_sentence': exampleSentence,
      };

  factory Word.fromMap(Map<String, dynamic> map) => Word(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        word: map['word'] as String,
        translation: map['translation'] as String? ?? '',
        easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: map['interval_days'] as int? ?? 1,
        repetitions: map['repetitions'] as int? ?? 0,
        nextReview: map['next_review'] != null
            ? DateTime.parse(map['next_review'] as String)
            : DateTime.now(),
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        ipa: map['ipa'] as String?,
        exampleSentence: map['example_sentence'] as String?,
      );

  // SM-2 algoritması: quality 0=bilmedim, 3=zordu, 5=kolaydı
  Word reviewed(int quality) {
    int newReps = repetitions;
    int newInterval = intervalDays;
    double newEF = easeFactor;

    if (quality < 3) {
      newReps = 0;
      newInterval = 1;
    } else {
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (intervalDays * easeFactor).round();
      }
      newReps = repetitions + 1;
    }

    newEF = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    newEF = max(1.3, newEF);

    return Word(
      id: id,
      userId: userId,
      word: word,
      translation: translation,
      easeFactor: newEF,
      intervalDays: newInterval,
      repetitions: newReps,
      nextReview: DateTime.now().add(Duration(days: newInterval)),
      createdAt: createdAt,
      ipa: ipa,
      exampleSentence: exampleSentence,
    );
  }
}
