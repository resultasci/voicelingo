/// Sözlük girdisi — AI enrichment cache'i. `dictionary_entries` tablosundan.
///
/// Gemini IPA + enrichment'tan dolan ortak veri kümesi. Yeni
/// kelime sorulduğunda önce buradan okunur, yoksa AI'dan çekilip cache'lenir.
class DictionaryEntry {
  final String word;
  final String? pos;
  final String? ipa;
  final int? frequencyRank;
  final String? cefrLevel;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> collocations;
  final String? etymologyBrief;
  final List<DictExample> examples;
  final DateTime cachedAt;

  const DictionaryEntry({
    required this.word,
    required this.cachedAt,
    this.pos,
    this.ipa,
    this.frequencyRank,
    this.cefrLevel,
    this.synonyms = const [],
    this.antonyms = const [],
    this.collocations = const [],
    this.etymologyBrief,
    this.examples = const [],
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> map) => DictionaryEntry(
        word: map['word'] as String,
        pos: map['pos'] as String?,
        ipa: map['ipa'] as String?,
        frequencyRank: (map['frequency_rank'] as num?)?.toInt(),
        cefrLevel: map['cefr_level'] as String?,
        synonyms: _stringList(map['synonyms']),
        antonyms: _stringList(map['antonyms']),
        collocations: _stringList(map['collocations']),
        etymologyBrief: map['etymology_brief'] as String?,
        // Map.from: Hive round-trip'i iç map'leri Map<dynamic,dynamic> döndürür.
        examples: (map['examples'] as List? ?? const [])
            .map((e) =>
                DictExample.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        cachedAt: DateTime.tryParse(map['cached_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Cache (Hive) serileştirmesi — `fromMap` ile tam round-trip uyumlu.
  Map<String, dynamic> toMap() => {
        'word': word,
        'pos': pos,
        'ipa': ipa,
        'frequency_rank': frequencyRank,
        'cefr_level': cefrLevel,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'collocations': collocations,
        'etymology_brief': etymologyBrief,
        'examples': examples.map((e) => e.toJson()).toList(),
        'cached_at': cachedAt.toIso8601String(),
      };

  static List<String> _stringList(dynamic raw) {
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }
}

class DictExample {
  final String en;
  final String? tr;
  const DictExample({required this.en, this.tr});

  factory DictExample.fromJson(Map<String, dynamic> json) => DictExample(
        en: json['en'] as String? ?? '',
        tr: json['tr'] as String?,
      );

  Map<String, dynamic> toJson() => {'en': en, 'tr': tr};
}
