import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicelingo/core/ai/gemini_service.dart';
import 'package:voicelingo/core/errors/app_exception.dart' as app;
import 'package:voicelingo/core/storage/cached_repository.dart';
import 'package:voicelingo/features/words/models/dictionary_entry.dart';
import 'package:voicelingo/features/words/services/dictionary_service.dart';

void main() {
  late Directory tempDir;
  late Box<Map> box;

  // Geçersiz şema: HTTP istemcisi bağlantı denemeden anında fırlatır; servis
  // sözleşmesi gereği DB adımı sessizce AI fallback'ına düşer.
  final deadDb = SupabaseClient('invalid://blocked', 'test-anon-key');

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('dictionary_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<Map>('dict_test');
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  DictionaryService make(Future<WordEnrichment?> Function(String) enrich) =>
      DictionaryService(deadDb, cache: box, enrich: enrich);

  test('Hive hit enrichment çağırmadan döner', () async {
    await CachedRepository.put<DictionaryEntry>(
      box: box,
      key: 'apple',
      toJson: (e) => e.toMap(),
      value: DictionaryEntry(
        word: 'apple',
        ipa: '/ˈæp.əl/',
        examples: const [DictExample(en: 'An apple a day.')],
        cachedAt: DateTime.now(),
      ),
    );
    var enrichCalls = 0;
    final svc = make((_) async {
      enrichCalls++;
      return null;
    });

    final entry = await svc.lookup('  Apple ');

    expect(entry, isNotNull);
    expect(entry!.ipa, '/ˈæp.əl/');
    expect(entry.examples.single.en, 'An apple a day.');
    expect(enrichCalls, 0);
  });

  test('miss: AI sonucu döner ve Hive\'a geri yazılır', () async {
    var enrichCalls = 0;
    final svc = make((w) async {
      enrichCalls++;
      return const WordEnrichment(ipa: '/test/', example: 'Example sentence.');
    });

    final first = await svc.lookup('banana');
    expect(first, isNotNull);
    expect(first!.ipa, '/test/');
    expect(enrichCalls, 1);

    // İkinci bakış Hive'dan gelmeli — enrichment tekrar çağrılmaz.
    final second = await svc.lookup('banana');
    expect(second, isNotNull);
    expect(second!.examples.single.en, 'Example sentence.');
    expect(enrichCalls, 1);
  });

  test('AiException → null (sınır sözleşmesi korunur)', () async {
    final svc = make((_) async => throw app.AiException(429, 'limit'));
    expect(await svc.lookup('cherry'), isNull);
  });

  test('enrichment null dönerse null; cache kirletilmez', () async {
    final svc = make((_) async => null);
    expect(await svc.lookup('durian'), isNull);
    expect(box.get('durian'), isNull);
  });
}
