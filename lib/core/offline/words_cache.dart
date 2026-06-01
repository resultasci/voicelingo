import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/word.dart';
import '../storage/hive_boxes.dart';

/// Words için offline cache wrapper.
///
/// API: words_provider önce cache'i yazar (background sync sonrası), offline
/// olunca cache'ten okur. Tek-yön read-through cache: yazımlar online iken
/// Supabase'e gider; offline yazımlar `pending_ops` box'ına gider (Faz 10
/// future iteration — şimdilik write yapmıyoruz).
class WordsCache {
  WordsCache();

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.words);

  /// Tüm cache'lenmiş kelimeleri döndürür.
  List<Word> readAll() {
    final out = <Word>[];
    for (final v in _box.values) {
      try {
        final m = v.cast<String, dynamic>();
        out.add(Word.fromMap(m));
      } catch (_) {
        // Şema değişikliği olursa skip
      }
    }
    return out;
  }

  /// Online sync sonrası DB'den gelen listeyi cache'e yaz (replace-all).
  Future<void> putAll(List<Word> words) async {
    await _box.clear();
    final entries = <dynamic, Map<dynamic, dynamic>>{};
    for (final w in words) {
      entries[w.id] = w.toMap();
    }
    await _box.putAll(entries);
  }

  Future<void> clear() => _box.clear();

  bool get isEmpty => _box.isEmpty;
  int get size => _box.length;
}

final wordsCacheProvider = Provider<WordsCache>((ref) => WordsCache());
