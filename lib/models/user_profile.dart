class UserProfile {
  final String id;
  final String username;
  final int level;
  final int xp;
  final int streakDays;
  final String targetLanguage;
  final DateTime? streakLastDate;
  final DateTime? seededAt;
  final String? cefrLevel;
  // Faz 4: Onboarding + Gamification
  final int streakFreezes;
  final DateTime? lastActiveAt;
  final DateTime? onboardingCompletedAt;
  final int dailyMinuteGoal;
  final String? learningMotivation;

  const UserProfile({
    required this.id,
    required this.username,
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.targetLanguage,
    this.streakLastDate,
    this.seededAt,
    this.cefrLevel,
    this.streakFreezes = 0,
    this.lastActiveAt,
    this.onboardingCompletedAt,
    this.dailyMinuteGoal = 10,
    this.learningMotivation,
  });

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'level': level,
        'xp': xp,
        'streak_days': streakDays,
        'target_language': targetLanguage,
        'streak_last_date': streakLastDate?.toIso8601String(),
        'seeded_at': seededAt?.toIso8601String(),
        'cefr_level': cefrLevel,
        'streak_freezes': streakFreezes,
        'last_active_at': lastActiveAt?.toIso8601String(),
        'onboarding_completed_at': onboardingCompletedAt?.toIso8601String(),
        'daily_minute_goal': dailyMinuteGoal,
        'learning_motivation': learningMotivation,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        username: map['username'] as String? ?? 'Kullanıcı',
        level: map['level'] as int? ?? 1,
        xp: map['xp'] as int? ?? 0,
        streakDays: map['streak_days'] as int? ?? 0,
        targetLanguage: map['target_language'] as String? ?? 'en',
        streakLastDate: map['streak_last_date'] != null
            ? DateTime.tryParse(map['streak_last_date'] as String)
            : null,
        seededAt: map['seeded_at'] != null
            ? DateTime.tryParse(map['seeded_at'] as String)
            : null,
        cefrLevel: map['cefr_level'] as String?,
        streakFreezes: (map['streak_freezes'] as num?)?.toInt() ?? 0,
        lastActiveAt: map['last_active_at'] != null
            ? DateTime.tryParse(map['last_active_at'] as String)
            : null,
        onboardingCompletedAt: map['onboarding_completed_at'] != null
            ? DateTime.tryParse(map['onboarding_completed_at'] as String)
            : null,
        dailyMinuteGoal: (map['daily_minute_goal'] as num?)?.toInt() ?? 10,
        learningMotivation: map['learning_motivation'] as String?,
      );
}
