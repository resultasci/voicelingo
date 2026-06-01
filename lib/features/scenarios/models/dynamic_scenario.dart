import 'package:flutter/material.dart';

import '../../../models/scenario.dart';

/// DB-backed senaryo. Mevcut [ScenarioModel] in-memory built-in'ler için
/// kullanılmaya devam ediyor; bu sınıf hem sistem hem de kullanıcı tarafından
/// üretilen senaryoları temsil eder.
///
/// Conversation_screen mevcut `ScenarioModel`'i bekliyor; köprü için
/// [toScenarioModel] adapter'ı sağlanır.
class DynamicScenario {
  final String id;
  final String? userId;
  final bool isPublic;
  final String? category;
  final ScenarioDifficulty difficulty;
  final String titleEn;
  final String? titleTr;
  final String setting;
  final String aiRole;
  final String userRole;
  final String? starterLine;
  final List<String> keyPhrases;
  final List<String> objectives;
  final int estimatedTurns;
  final String? iconCode;
  final String? systemPrompt;
  final DateTime createdAt;

  const DynamicScenario({
    required this.id,
    required this.titleEn,
    required this.setting,
    required this.aiRole,
    required this.userRole,
    required this.difficulty,
    required this.estimatedTurns,
    required this.createdAt,
    this.userId,
    this.isPublic = false,
    this.category,
    this.titleTr,
    this.starterLine,
    this.keyPhrases = const [],
    this.objectives = const [],
    this.iconCode,
    this.systemPrompt,
  });

  bool get isSystem => userId == null;
  String title(String locale) =>
      (locale == 'tr' && titleTr != null && titleTr!.isNotEmpty)
          ? titleTr!
          : titleEn;

  /// Conversation_screen için adapter. Eğer DB'de system_prompt kayıtlı değilse
  /// runtime'da setting + aiRole + objectives birleştirilerek üretilir.
  ScenarioModel toScenarioModel() {
    final prompt = systemPrompt?.isNotEmpty == true
        ? systemPrompt!
        : _buildSystemPromptFromFields();
    return ScenarioModel(
      id: id,
      title: titleTr ?? titleEn,
      description: setting,
      systemPrompt: prompt,
      openingLine: starterLine ?? '',
      icon: _resolveIcon(iconCode),
    );
  }

  String _buildSystemPromptFromFields() {
    final buf = StringBuffer();
    buf.writeln('Setting: $setting');
    buf.writeln('Your role: $aiRole');
    buf.writeln('Their role: $userRole');
    if (objectives.isNotEmpty) {
      buf.writeln(
          'Conversation goals for the learner: ${objectives.join(", ")}');
    }
    if (keyPhrases.isNotEmpty) {
      buf.writeln(
          'Try to elicit phrases like: ${keyPhrases.join(", ")} (do not list them explicitly).');
    }
    buf.writeln('Keep responses 1-3 sentences. Stay in character.');
    return buf.toString();
  }

  IconData _resolveIcon(String? code) {
    switch (code) {
      case 'local_cafe_outlined':
        return Icons.local_cafe_outlined;
      case 'work_outline':
        return Icons.work_outline;
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'people_alt_outlined':
        return Icons.people_alt_outlined;
      case 'flight_takeoff_outlined':
        return Icons.flight_takeoff_outlined;
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'hotel_outlined':
        return Icons.hotel_outlined;
      case 'shopping_cart_outlined':
        return Icons.shopping_cart_outlined;
      case 'phone_outlined':
        return Icons.phone_outlined;
      default:
        return Icons.theater_comedy_outlined;
    }
  }

  factory DynamicScenario.fromMap(Map<String, dynamic> map) {
    List<String> toStringList(dynamic raw) {
      if (raw is List) return raw.whereType<String>().toList();
      return const [];
    }

    return DynamicScenario(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      category: map['category'] as String?,
      difficulty: ScenarioDifficulty.fromCode(map['difficulty'] as String?),
      titleEn: map['title_en'] as String? ?? '',
      titleTr: map['title_tr'] as String?,
      setting: map['setting'] as String? ?? '',
      aiRole: map['ai_role'] as String? ?? '',
      userRole: map['user_role'] as String? ?? '',
      starterLine: map['starter_line'] as String?,
      keyPhrases: toStringList(map['key_phrases']),
      objectives: toStringList(map['objectives']),
      estimatedTurns: (map['estimated_turns'] as num?)?.toInt() ?? 6,
      iconCode: map['icon_code'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum ScenarioDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  final String code;
  const ScenarioDifficulty(this.code);

  static ScenarioDifficulty fromCode(String? c) => ScenarioDifficulty.values
      .firstWhere((d) => d.code == c, orElse: () => ScenarioDifficulty.medium);

  String label(String locale) {
    switch (this) {
      case easy:
        return locale == 'en' ? 'Easy' : 'Kolay';
      case medium:
        return locale == 'en' ? 'Medium' : 'Orta';
      case hard:
        return locale == 'en' ? 'Hard' : 'Zor';
    }
  }
}
