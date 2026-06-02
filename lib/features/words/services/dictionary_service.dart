import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/gemini_service.dart';
import '../models/dictionary_entry.dart';

/// Sözlük cache'i + AI enrichment yöneticisi.
///
/// Bir kelime soruldu:
///   1. dictionary_entries cache'inden oku — varsa direkt döndür.
///   2. Yoksa Gemini'nin /enrich endpoint'inden (ai-proxy) zenginleştirme al (IPA + example).
///   3. Cache'e yaz, döndür.
///
/// `/enrich-full` (synonyms/antonyms/etymology) endpoint'i henüz yok — Faz 6'da
/// eklenecek edge function. Şimdilik mevcut `/enrich`'ten gelen veriyle yaşıyoruz.
class DictionaryService {
  DictionaryService(this._db, this._ref);
  final SupabaseClient _db;
  final Ref _ref;

  /// Cache veya AI'dan enriched DictionaryEntry getir.
  Future<DictionaryEntry?> lookup(String word) async {
    final normalized = word.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // 1) Cache
    try {
      final row = await _db
          .from('dictionary_entries')
          .select()
          .eq('word', normalized)
          .maybeSingle();
      if (row != null) {
        return DictionaryEntry.fromMap(row);
      }
    } catch (_) {
      // Cache okuma hatası — AI fallback'a düş
    }

    // 2) AI enrichment
    try {
      final ai = _ref.read(geminiServiceProvider);
      final enriched = await ai.enrichWord(normalized);
      if (enriched == null) return null;

      final examples = enriched.example != null && enriched.example!.isNotEmpty
          ? [
              {'en': enriched.example}
            ]
          : <Map<String, dynamic>>[];

      // 3) Cache yaz — RLS yüzünden bu authenticated user için mümkün
      // olmayabilir; o durumda sessizce geç ve in-memory bir entry döndür.
      try {
        await _db.from('dictionary_entries').upsert({
          'word': normalized,
          'ipa': enriched.ipa,
          'examples': examples,
          'cached_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        // Insert RLS yasaklıyorsa cache'lemeden döndür
      }

      return DictionaryEntry(
        word: normalized,
        ipa: enriched.ipa,
        examples: examples.map((m) => DictExample.fromJson(m)).toList(),
        cachedAt: DateTime.now(),
      );
    } on AiException {
      return null;
    }
  }
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService(Supabase.instance.client, ref);
});

/// Bir kelime için DictionaryEntry — UI'da `family('apple')` gibi kullanılır.
final dictionaryEntryProvider =
    FutureProvider.autoDispose.family<DictionaryEntry?, String>(
  (ref, word) async {
    final svc = ref.watch(dictionaryServiceProvider);
    return svc.lookup(word);
  },
);
