import 'prompts/turkish_learner_notes.dart';

/// AI koç karakter tanımı.
///
/// Karakter, kullanıcının konuştuğu sanal kişiliktir. Her karakter farklı:
///   - Ses (TTS voice ID + pitch + speech rate)
///   - Aksan (American/British/Australian)
///   - Kişilik (samimi/sert/profesyonel/gezgin)
///   - System prompt (AI'a giden talimatlar)
///   - Bio (kullanıcıya gösterilen tanıtım)
///
/// Karakterler [characters.dart]'ta hardcoded — DB tarafında sadece
/// `selected_character_id` saklanır. Karakter ekleme = yeni Dart sabiti.
class AICharacter {
  final String id;
  final String displayName;
  final int age;
  final String accent;
  final String personality;

  /// 'female' | 'male' — drives the vector avatar styling (ring style) and the
  /// 3F/3M grouping in the picker. Not sent to the AI.
  final String gender;

  /// Emoji glyph — kept as a lightweight fallback motif inside the vector
  /// [CharacterAvatar]; no longer the primary avatar.
  final String avatarEmoji;

  // TTS özellikleri — flutter_tts.setVoice ile eşleşir
  final String ttsLocale;
  final double ttsPitch;
  final double ttsRate;
  final Set<String> ttsVoiceHints;

  // System prompt — {{level}} placeholder runtime'da değiştirilir
  final String systemPromptTemplate;

  // Bio metinleri
  final String bioTr;
  final String bioEn;

  // İlk açılış cümlesi (kullanıcıyı tanırken söyler — TTS örneği için)
  final String introLine;

  const AICharacter({
    required this.id,
    required this.displayName,
    required this.age,
    required this.accent,
    required this.personality,
    required this.gender,
    required this.avatarEmoji,
    required this.ttsLocale,
    required this.systemPromptTemplate,
    required this.bioTr,
    required this.bioEn,
    required this.introLine,
    this.ttsPitch = 1.0,
    this.ttsRate = 0.5,
    this.ttsVoiceHints = const {},
  });

  /// Runtime'da kullanıcının CEFR seviyesini ve opsiyonel senaryo bağlamını
  /// yerleştirip AI'a gönderilecek system prompt'u üretir.
  ///
  /// Pedagogical notes always append at the end so every character benefits
  /// from L1 interference awareness without duplicating the same boilerplate
  /// in each character definition.
  String renderSystemPrompt({
    String cefrLevel = 'A2',
    String? scenarioContext,
  }) {
    final filled = systemPromptTemplate.replaceAll('{{level}}', cefrLevel);
    final withScenario = scenarioContext != null && scenarioContext.isNotEmpty
        ? '$filled\n\nScenario context: $scenarioContext'
        : filled;
    return '$withScenario${TurkishLearnerNotes.note}';
  }

  String bio(String locale) => locale == 'en' ? bioEn : bioTr;
}
