import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge.dart';

/// Rozet katalog + kullanıcı rozetleri için Supabase repository.
///
/// Badge unlock atomatik olarak `try_award_badge` RPC üzerinden yapılır
/// (double-award önler, XP'yi atomik uygular).
class BadgesService {
  BadgesService(this._db);
  final SupabaseClient _db;

  /// Tüm rozet kataloğu.
  Future<List<LearningBadge>> listAll() async {
    final data = await _db.from('badges').select().order('code');
    return (data as List)
        .map((e) => LearningBadge.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Kullanıcının kazandığı rozetler (badges JOIN user_badges).
  Future<List<EarnedBadge>> listEarned() async {
    final user = _db.auth.currentUser;
    if (user == null) return const [];
    final data = await _db
        .from('user_badges')
        .select('earned_at, badges(*)')
        .eq('user_id', user.id)
        .order('earned_at', ascending: false);

    final result = <EarnedBadge>[];
    for (final row in (data as List)) {
      final m = row as Map<String, dynamic>;
      final badgeMap = m['badges'] as Map<String, dynamic>?;
      if (badgeMap == null) continue;
      result.add(EarnedBadge(
        badge: LearningBadge.fromMap(badgeMap),
        earnedAt: DateTime.parse(m['earned_at'] as String),
      ));
    }
    return result;
  }

  /// Belirli bir rozetin koşulu sağlandıysa atomik olarak unlock et.
  /// Önceden kazanılmışsa veya kullanıcı oturum dışıysa null döner.
  /// Başarılı unlock'ta [Badge] + XP reward bilgisi döner.
  Future<BadgeAwardResult?> tryAward(String badgeCode) async {
    final res = await _db.rpc('try_award_badge', params: {
      'p_badge_code': badgeCode,
    });
    if (res is! Map<String, dynamic>) return null;
    if (res['ok'] != true) return null;
    return BadgeAwardResult(
      badgeId: res['badge_id'] as String,
      nameTr: res['name_tr'] as String,
      nameEn: res['name_en'] as String,
      icon: res['icon'] as String?,
      xpReward: (res['xp_reward'] as num?)?.toInt() ?? 0,
    );
  }
}

class BadgeAwardResult {
  final String badgeId;
  final String nameTr;
  final String nameEn;
  final String? icon;
  final int xpReward;

  const BadgeAwardResult({
    required this.badgeId,
    required this.nameTr,
    required this.nameEn,
    required this.xpReward,
    this.icon,
  });

  String name(String locale) => locale == 'en' ? nameEn : nameTr;
}
