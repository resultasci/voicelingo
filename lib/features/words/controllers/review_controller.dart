import 'package:flutter/foundation.dart';

import '../../../core/models/word.dart';

/// Flashcard review oturumunun state makinesi — eskiden WordsScreen'de
/// 9 ayrı alan + setState olarak dağınık duran akış.
///
/// SM-2 kalite puanları oturum boyunca [_batch]'te birikir ve son kartta
/// tek seferde [_commit] ile yazılır (commit_word_reviews RPC).
class ReviewController extends ChangeNotifier {
  ReviewController({
    required Future<void> Function(List<({String wordId, int quality})> batch)
        commit,
    this.onCommitError,
  }) : _commit = commit;

  final Future<void> Function(List<({String wordId, int quality})>) _commit;

  /// Batch kaydı başarısız olduğunda UI'ın uyarı göstermesi için.
  final VoidCallback? onCommitError;

  bool _isReviewing = false;
  bool get isReviewing => _isReviewing;

  bool _isDone = false;
  bool get isDone => _isDone;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isRating = false;
  bool get isRating => _isRating;

  bool _revealed = false;
  bool get revealed => _revealed;

  List<Word> _queue = [];
  List<Word> get queue => _queue;

  int _index = 0;
  int get index => _index;

  int _correct = 0;
  int get correct => _correct;

  final List<({String wordId, int quality})> _batch = [];

  bool get hasCurrent => _queue.isNotEmpty && _index < _queue.length;
  Word get current => _queue[_index];

  void start(List<Word> due) {
    if (due.isEmpty) return;
    _queue = due;
    _index = 0;
    _revealed = false;
    _correct = 0;
    _isReviewing = true;
    _isDone = false;
    _isRating = false;
    _batch.clear();
    notifyListeners();
  }

  void reveal() {
    _revealed = true;
    notifyListeners();
  }

  Future<void> rate(int quality) async {
    if (_isRating) return;
    if (_index >= _queue.length) {
      _isReviewing = false;
      _isDone = true;
      notifyListeners();
      return;
    }

    _isRating = true;
    notifyListeners();

    final word = _queue[_index];
    if (quality >= 3) _correct++;
    _batch.add((wordId: word.id, quality: quality));

    if (_index < _queue.length - 1) {
      _index++;
      _revealed = false;
      _isRating = false;
      notifyListeners();
    } else {
      _isSaving = true;
      notifyListeners();
      try {
        await _commit(_batch);
      } catch (_) {
        onCommitError?.call();
      }
      _isReviewing = false;
      _isDone = true;
      _isRating = false;
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Queue tükenmiş ama done'a geçilmemişse (savunma dalı) oturumu kapatır.
  void forceComplete() {
    _isReviewing = false;
    _isDone = true;
    notifyListeners();
  }

  void closeCompletion() {
    _isDone = false;
    _isReviewing = false;
    notifyListeners();
  }

  void exitReview() {
    _isReviewing = false;
    notifyListeners();
  }
}
