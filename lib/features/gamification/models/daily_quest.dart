/// Günlük görev — kullanıcıya her gün 3 farklı görev üretilir, tamamlama XP'si
/// ile birlikte streak günü olarak sayılır.
class DailyQuest {
  final String id;
  final String userId;
  final DateTime questDate;
  final QuestType type;
  final int target;
  final int progress;
  final DateTime? completedAt;
  final int xpReward;

  const DailyQuest({
    required this.id,
    required this.userId,
    required this.questDate,
    required this.type,
    required this.target,
    required this.progress,
    required this.xpReward,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;
  double get progressRatio => target == 0 ? 0 : (progress / target).clamp(0, 1);

  factory DailyQuest.fromMap(Map<String, dynamic> map) => DailyQuest(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        questDate: DateTime.parse(map['quest_date'] as String),
        type: QuestType.fromCode(map['quest_type'] as String),
        target: (map['target'] as num).toInt(),
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        completedAt: map['completed_at'] != null
            ? DateTime.tryParse(map['completed_at'] as String)
            : null,
        xpReward: (map['xp_reward'] as num).toInt(),
      );
}

/// Görev tipleri — yeni tip eklerken QuestType.values'a + i18n string'lerine ekle.
enum QuestType {
  learnWords('learn_words', 'Yeni kelime öğren', 'Learn new words'),
  reviewWords('review_words', 'Kelime tekrarla', 'Review words'),
  practiceMinutes('practice_minutes', 'Pratik yap', 'Practice'),
  conversationTurns('conversation_turns', 'Konuşma turu tamamla',
      'Complete conversation turns'),
  perfectScore('perfect_score', 'Mükemmel skor al', 'Get a perfect score');

  final String code;
  final String labelTr;
  final String labelEn;
  const QuestType(this.code, this.labelTr, this.labelEn);

  static QuestType fromCode(String code) =>
      QuestType.values.firstWhere((t) => t.code == code,
          orElse: () => QuestType.practiceMinutes);

  String label(String locale) => locale == 'en' ? labelEn : labelTr;
}
