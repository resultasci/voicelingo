/// Sözlük girdisi — AI enrichment cache'i. `dictionary_entries` tablosundan.
///
/// Whisper IPA + Groq enrichment'tan dolan ortak veri kümesi. Yeni
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
        examples: (map['examples'] as List? ?? const [])
            .map((e) => DictExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        cachedAt: DateTime.tryParse(map['cached_at'] as String? ?? '') ??
            DateTime.now(),
      );

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
}
