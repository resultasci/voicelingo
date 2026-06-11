import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/gemini_service.dart';
import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../models/dictionary_entry.dart';

/// Sözlük cache'i + AI enrichment yöneticisi.
///
/// Bir kelime soruldu:
///   0. Hive (`dictionary_v1`) — tekrar bakışlar sıfır round-trip; sözlük
///      verisi statik olduğundan 30 gün TTL.
///   1. dictionary_entries DB cache'i — varsa Hive'a yazıp döndür.
///   2. Yoksa Gemini'nin /enrich endpoint'inden (ai-proxy) zenginleştirme al.
///   3. DB + Hive'a yaz, döndür.
///
/// Enrichment closure ile inject edilir (test: gerçek Gemini'siz sahte).
/// `/enrich-full` (synonyms/antonyms/etymology) endpoint'i henüz yok — Faz 6'da
/// eklenecek edge function. Şimdilik mevcut `/enrich`'ten gelen veriyle yaşıyoruz.
class DictionaryService {
  DictionaryService(
    this._db, {
    required Box<Map> cache,
    required Future<WordEnrichment?> Function(String word) enrich,
  })  : _cache = cache,
        _enrich = enrich;

  final SupabaseClient _db;
  final Box<Map> _cache;
  final Future<WordEnrichment?> Function(String word) _enrich;

  static const _maxAge = Duration(days: 30);

  /// Cache veya AI'dan enriched DictionaryEntry getir.
  Future<DictionaryEntry?> lookup(String word) async {
    final normalized = word.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // 0) Hive
    final local = CachedRepository.peek<DictionaryEntry>(
      box: _cache,
      key: normalized,
      fromJson: DictionaryEntry.fromMap,
      maxAge: _maxAge,
    );
    if (local != null) return local;

    Future<void> writeLocal(DictionaryEntry entry) =>
        CachedRepository.put<DictionaryEntry>(
          box: _cache,
          key: normalized,
          toJson: (e) => e.toMap(),
          value: entry,
        );

    // 1) DB cache
    try {
      final row = await _db
          .from('dictionary_entries')
          .select()
          .eq('word', normalized)
          .maybeSingle();
      if (row != null) {
        final entry = DictionaryEntry.fromMap(row);
        await writeLocal(entry);
        return entry;
      }
    } catch (_) {
      // DB cache okuma hatası — AI fallback'a düş
    }

    // 2) AI enrichment
    try {
      final enriched = await _enrich(normalized);
      if (enriched == null) return null;

      final examples = enriched.example != null && enriched.example!.isNotEmpty
          ? [
              {'en': enriched.example}
            ]
          : <Map<String, dynamic>>[];

      // 3) DB cache yaz — RLS yüzünden bu authenticated user için mümkün
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

      final entry = DictionaryEntry(
        word: normalized,
        ipa: enriched.ipa,
        examples: examples.map((m) => DictExample.fromJson(m)).toList(),
        cachedAt: DateTime.now(),
      );
      await writeLocal(entry);
      return entry;
    } on AiException {
      return null;
    }
  }
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService(
    Supabase.instance.client,
    cache: Hive.box<Map>(HiveBoxes.dictionary),
    enrich: (w) => ref.read(geminiServiceProvider).enrichWord(w),
  );
});

/// Bir kelime için DictionaryEntry — UI'da `family('apple')` gibi kullanılır.
final dictionaryEntryProvider =
    FutureProvider.autoDispose.family<DictionaryEntry?, String>(
  (ref, word) async {
    final svc = ref.watch(dictionaryServiceProvider);
    return svc.lookup(word);
  },
);
