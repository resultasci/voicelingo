import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voicelingo/core/storage/cached_repository.dart';
import 'package:voicelingo/features/grammar/models/grammar_topic.dart';
import 'package:voicelingo/features/lessons/models/course.dart';

/// progress_v1 cache'inin liste-sarmalama adapter'ı gerçek bir Hive box
/// üzerinden round-trip edilir. Hive int→double genişletmesi (CLAUDE.md
/// tuzağı) attempts/stars gibi alanlarda `(x as num?)?.toInt()` ile
/// karşılanmalı — bu test onu gerçek diskte doğrular.
void main() {
  late Directory tempDir;
  late Box<Map> box;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('progress_cache_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<Map>('progress_test');
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('UserLessonProgress liste-sarmalama round-trip (int alanlar sağ kalır)',
      () async {
    final original = UserLessonProgress(
      userId: 'u1',
      lessonId: 'l1',
      status: LessonStatus.completed,
      stars: 3,
      bestScore: 87,
      attempts: 2,
      lastAttemptAt: DateTime.utc(2026, 6, 11, 10, 30),
      nextReviewAt: DateTime.utc(2026, 6, 18),
    );

    Map<String, UserLessonProgress> fromJson(Map<String, dynamic> m) => {
          for (final e in (m['list'] as List? ?? const []))
            (Map<String, dynamic>.from(e as Map)['lesson_id'] as String):
                UserLessonProgress.fromMap(Map<String, dynamic>.from(e)),
        };

    await CachedRepository.getOrFetch<Map<String, UserLessonProgress>>(
      box: box,
      key: 'k',
      fromJson: fromJson,
      toJson: (map) => {'list': map.values.map((p) => p.toMap()).toList()},
      fetchRemote: () async => {'l1': original},
    );

    // İkinci okuma cache'ten gelir (fetchRemote patlarsa bile).
    final cached =
        await CachedRepository.getOrFetch<Map<String, UserLessonProgress>>(
      box: box,
      key: 'k',
      fromJson: fromJson,
      toJson: (map) => {'list': map.values.map((p) => p.toMap()).toList()},
      fetchRemote: () async => throw Exception('remote down'),
    );

    final p = cached['l1']!;
    expect(p.status, LessonStatus.completed);
    expect(p.stars, 3);
    expect(p.bestScore, 87);
    expect(p.attempts, 2);
    expect(p.lastAttemptAt, DateTime.utc(2026, 6, 11, 10, 30));
    expect(p.nextReviewAt, DateTime.utc(2026, 6, 18));
  });

  test('GrammarProgress liste-sarmalama round-trip', () async {
    final original = GrammarProgress(
      userId: 'u1',
      topicId: 't1',
      status: GrammarStatus.mastered,
      quizScore: 96,
      attempts: 4,
      completedAt: DateTime.utc(2026, 6, 10),
    );

    Map<String, GrammarProgress> fromJson(Map<String, dynamic> m) => {
          for (final e in (m['list'] as List? ?? const []))
            (Map<String, dynamic>.from(e as Map)['topic_id'] as String):
                GrammarProgress.fromMap(Map<String, dynamic>.from(e)),
        };

    await CachedRepository.getOrFetch<Map<String, GrammarProgress>>(
      box: box,
      key: 'k',
      fromJson: fromJson,
      toJson: (map) => {'list': map.values.map((p) => p.toMap()).toList()},
      fetchRemote: () async => {'t1': original},
    );

    final cached =
        await CachedRepository.getOrFetch<Map<String, GrammarProgress>>(
      box: box,
      key: 'k',
      fromJson: fromJson,
      toJson: (map) => {'list': map.values.map((p) => p.toMap()).toList()},
      fetchRemote: () async => throw Exception('remote down'),
    );

    final p = cached['t1']!;
    expect(p.status, GrammarStatus.mastered);
    expect(p.quizScore, 96);
    expect(p.attempts, 4);
    expect(p.completedAt, DateTime.utc(2026, 6, 10));
  });
}
