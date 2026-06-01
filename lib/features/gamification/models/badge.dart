/// Rozet kataloğu satırı. Supabase `badges` tablosunun client karşılığı.
///
/// `criteria` jsonb olarak gelir; client tarafı bunu tip-güvenli değerlendirmek
/// için [BadgeCriteria.fromJson]'a iletir.
class LearningBadge {
  final String id;
  final String code;
  final String nameTr;
  final String nameEn;
  final String? descriptionTr;
  final String? descriptionEn;
  final String? icon;
  final BadgeCriteria criteria;
  final int xpReward;

  const LearningBadge({
    required this.id,
    required this.code,
    required this.nameTr,
    required this.nameEn,
    required this.criteria,
    this.descriptionTr,
    this.descriptionEn,
    this.icon,
    this.xpReward = 0,
  });

  String displayName(String locale) => locale == 'en' ? nameEn : nameTr;
  String? displayDescription(String locale) =>
      locale == 'en' ? descriptionEn : descriptionTr;

  factory LearningBadge.fromMap(Map<String, dynamic> map) => LearningBadge(
        id: map['id'] as String,
        code: map['code'] as String,
        nameTr: map['name_tr'] as String,
        nameEn: map['name_en'] as String,
        descriptionTr: map['description_tr'] as String?,
        descriptionEn: map['description_en'] as String?,
        icon: map['icon'] as String?,
        criteria:
            BadgeCriteria.fromJson(map['criteria'] as Map<String, dynamic>),
        xpReward: (map['xp_reward'] as num?)?.toInt() ?? 0,
      );
}

/// Bir rozetin kazanım koşulu. Tip alanına göre farklı parametreler taşır.
sealed class BadgeCriteria {
  const BadgeCriteria();

  factory BadgeCriteria.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final target = (json['target'] as num?)?.toInt();
    switch (type) {
      case 'streak':
        return StreakCriteria(target ?? 0);
      case 'words_mastered':
        return WordsMasteredCriteria(target ?? 0);
      case 'conversation_turns':
        return ConversationTurnsCriteria(target ?? 0);
      case 'perfect_scores':
        return PerfectScoresCriteria(target ?? 0);
      case 'scenarios_completed':
        return ScenariosCompletedCriteria(target ?? 0);
      case 'time_window':
        final w = json['window'] as String? ?? '';
        return TimeWindowCriteria(w);
      default:
        return UnknownCriteria(type ?? 'unknown');
    }
  }
}

class StreakCriteria extends BadgeCriteria {
  final int target;
  const StreakCriteria(this.target);
}

class WordsMasteredCriteria extends BadgeCriteria {
  final int target;
  const WordsMasteredCriteria(this.target);
}

class ConversationTurnsCriteria extends BadgeCriteria {
  final int target;
  const ConversationTurnsCriteria(this.target);
}

class PerfectScoresCriteria extends BadgeCriteria {
  final int target;
  const PerfectScoresCriteria(this.target);
}

class ScenariosCompletedCriteria extends BadgeCriteria {
  final int target;
  const ScenariosCompletedCriteria(this.target);
}

class TimeWindowCriteria extends BadgeCriteria {
  /// 'morning' (06-09) veya 'night' (22-02)
  final String window;
  const TimeWindowCriteria(this.window);
}

class UnknownCriteria extends BadgeCriteria {
  final String type;
  const UnknownCriteria(this.type);
}

/// Kullanıcının kazandığı bir rozet (badges + earned_at join).
class EarnedBadge {
  final LearningBadge badge;
  final DateTime earnedAt;
  const EarnedBadge({required this.badge, required this.earnedAt});
}
