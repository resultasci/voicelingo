import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/models/word.dart';

Word makeWord({
  double easeFactor = 2.5,
  int intervalDays = 1,
  int repetitions = 0,
}) {
  return Word(
    id: 'w1',
    userId: 'u1',
    word: 'serendipity',
    translation: 'şans eseri keşif',
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReview: DateTime(2026, 1, 1),
    createdAt: DateTime(2025, 12, 1),
  );
}

void main() {
  group('Word.reviewed SM-2', () {
    test('quality < 3 resets repetitions and interval', () {
      final w = makeWord(repetitions: 4, intervalDays: 30).reviewed(2);
      expect(w.repetitions, 0);
      expect(w.intervalDays, 1);
    });

    test('first successful review: interval 1, repetitions 1', () {
      final w = makeWord().reviewed(5);
      expect(w.repetitions, 1);
      expect(w.intervalDays, 1);
    });

    test('second successful review: interval jumps to 6', () {
      final w = makeWord(repetitions: 1, intervalDays: 1).reviewed(4);
      expect(w.repetitions, 2);
      expect(w.intervalDays, 6);
    });

    test('third+ review: interval = round(interval * easeFactor)', () {
      final w = makeWord(repetitions: 2, intervalDays: 6, easeFactor: 2.5)
          .reviewed(5);
      expect(w.repetitions, 3);
      expect(w.intervalDays, 15); // round(6 * 2.5)
    });

    test('ease factor: q=5 +0.1, q=4 unchanged, q=3 -0.14', () {
      expect(makeWord().reviewed(5).easeFactor, closeTo(2.6, 1e-9));
      expect(makeWord().reviewed(4).easeFactor, closeTo(2.5, 1e-9));
      expect(makeWord().reviewed(3).easeFactor, closeTo(2.36, 1e-9));
    });

    test('ease factor never drops below 1.3 floor', () {
      var w = makeWord(easeFactor: 1.35);
      w = w.reviewed(0); // -0.8 → clamps at 1.3
      expect(w.easeFactor, 1.3);
      w = w.reviewed(0);
      expect(w.easeFactor, 1.3);
    });

    test('failed review still updates ease factor (SM-2 spec)', () {
      final w = makeWord(easeFactor: 2.5).reviewed(0);
      expect(w.easeFactor, closeTo(1.7, 1e-9)); // 2.5 - 0.8
    });

    test('nextReview lands interval days in the future', () {
      final before = DateTime.now();
      final w = makeWord(repetitions: 1, intervalDays: 1).reviewed(4);
      final expected = before.add(const Duration(days: 6));
      expect(
        w.nextReview.difference(expected).inMinutes.abs() <= 1,
        isTrue,
        reason: 'nextReview ~now+6d olmalı, bulundu: ${w.nextReview}',
      );
    });

    test('identity fields survive a review', () {
      final w = makeWord().reviewed(5);
      expect(w.id, 'w1');
      expect(w.userId, 'u1');
      expect(w.word, 'serendipity');
      expect(w.translation, 'şans eseri keşif');
      expect(w.createdAt, DateTime(2025, 12, 1));
    });
  });

  group('Word map round-trip', () {
    test('toMap → fromMap preserves SM-2 state', () {
      final original = makeWord(
        easeFactor: 2.18,
        intervalDays: 12,
        repetitions: 3,
      );
      final restored = Word.fromMap(original.toMap());
      expect(restored.easeFactor, original.easeFactor);
      expect(restored.intervalDays, original.intervalDays);
      expect(restored.repetitions, original.repetitions);
      expect(restored.nextReview, original.nextReview);
    });

    test('fromMap tolerates Hive int→double widening', () {
      final map = makeWord().toMap();
      map['interval_days'] = 6.0;
      map['repetitions'] = 2.0;
      final w = Word.fromMap(map);
      expect(w.intervalDays, 6);
      expect(w.repetitions, 2);
    });
  });
}
