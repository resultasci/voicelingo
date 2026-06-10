import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voicelingo/core/storage/cached_repository.dart';

void main() {
  late Directory tempDir;
  late Box<Map> box;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('cached_repo_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<Map>('cache_test');
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Map<String, dynamic> identity(Map<String, dynamic> m) => m;

  test('miss blocks on remote and caches the result', () async {
    var fetches = 0;
    final v = await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      fetchRemote: () async {
        fetches++;
        return {'name': 'fresh'};
      },
    );
    expect(v['name'], 'fresh');
    expect(fetches, 1);
    expect(box.get('k'), isNotNull);
  });

  test('hit returns cache without blocking on remote', () async {
    await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      fetchRemote: () async => {'name': 'v1'},
    );
    final v = await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      // Arka plan refresh'i hata verirse bile cache cevabı dönmüş olmalı.
      fetchRemote: () async => throw Exception('remote down'),
    );
    expect(v['name'], 'v1');
  });

  test('expired entry (maxAge) falls through to remote', () async {
    // 6 saatlik profil penceresi senaryosu: girdiyi 7 saat eskiye tarihle.
    await box.put('k', {
      '_cached_at': DateTime.now()
          .subtract(const Duration(hours: 7))
          .millisecondsSinceEpoch,
      'data': {'name': 'stale'},
    });
    final v = await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      maxAge: const Duration(hours: 6),
      fetchRemote: () async => {'name': 'fresh'},
    );
    expect(v['name'], 'fresh');
  });

  test('invalidate busts the entry', () async {
    await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      fetchRemote: () async => {'name': 'v1'},
    );
    await CachedRepository.invalidate(box, 'k');
    expect(box.get('k'), isNull);
  });

  test('corrupt cache entry is treated as a miss', () async {
    await box.put('k', {'_cached_at': DateTime.now().millisecondsSinceEpoch});
    final v = await CachedRepository.getOrFetch<Map<String, dynamic>>(
      box: box,
      key: 'k',
      fromJson: identity,
      toJson: identity,
      fetchRemote: () async => {'name': 'fresh'},
    );
    expect(v['name'], 'fresh');
  });
}
