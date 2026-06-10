import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/models/word.dart';
import 'package:voicelingo/features/words/controllers/review_controller.dart';

Word makeWord(String id) => Word(
      id: id,
      userId: 'u1',
      word: 'w$id',
      translation: 't$id',
      nextReview: DateTime(2026),
      createdAt: DateTime(2025),
    );

void main() {
  test('start initializes the session', () {
    final c = ReviewController(commit: (_) async {});
    c.start([makeWord('a'), makeWord('b')]);
    expect(c.isReviewing, isTrue);
    expect(c.isDone, isFalse);
    expect(c.index, 0);
    expect(c.current.id, 'a');
    expect(c.revealed, isFalse);
  });

  test('start with empty list is a no-op', () {
    final c = ReviewController(commit: (_) async {});
    c.start(const []);
    expect(c.isReviewing, isFalse);
  });

  test('rating advances and hides the answer again', () async {
    final c = ReviewController(commit: (_) async {});
    c.start([makeWord('a'), makeWord('b')]);
    c.reveal();
    expect(c.revealed, isTrue);
    await c.rate(5);
    expect(c.index, 1);
    expect(c.revealed, isFalse);
    expect(c.isReviewing, isTrue);
  });

  test('last card commits the whole batch once and completes', () async {
    List<({String wordId, int quality})>? committed;
    var commitCalls = 0;
    final c = ReviewController(commit: (batch) async {
      commitCalls++;
      committed = List.of(batch);
    });
    c.start([makeWord('a'), makeWord('b')]);
    await c.rate(5);
    await c.rate(2);
    expect(commitCalls, 1);
    expect(committed, [
      (wordId: 'a', quality: 5),
      (wordId: 'b', quality: 2),
    ]);
    expect(c.isDone, isTrue);
    expect(c.isReviewing, isFalse);
    expect(c.isSaving, isFalse);
    expect(c.correct, 1); // quality >= 3 sayılır
  });

  test('commit failure fires onCommitError but still completes', () async {
    var errored = false;
    final c = ReviewController(
      commit: (_) async => throw Exception('db down'),
      onCommitError: () => errored = true,
    );
    c.start([makeWord('a')]);
    await c.rate(4);
    expect(errored, isTrue);
    expect(c.isDone, isTrue);
    expect(c.isSaving, isFalse);
  });

  test('re-entrant rate calls are ignored while rating', () async {
    var commitCalls = 0;
    final c = ReviewController(commit: (_) async {
      commitCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    c.start([makeWord('a')]);
    final f1 = c.rate(5);
    final f2 = c.rate(5); // isRating true iken — yutulmalı
    await Future.wait([f1, f2]);
    expect(commitCalls, 1);
  });
}
