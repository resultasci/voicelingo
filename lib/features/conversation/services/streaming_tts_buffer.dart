import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Splits an incoming token stream into sentence-sized chunks and feeds them
/// to FlutterTts one at a time, so audio playback starts as soon as the first
/// sentence boundary arrives instead of after the full reply.
///
/// Boundaries: `.` `!` `?` and newline. Trailing punctuation is kept with the
/// sentence; whitespace is trimmed before speaking. A final `flush` speaks any
/// remainder that didn't end with punctuation.
///
/// Even when the upstream `/turn` endpoint returns a full reply (non-stream),
/// the buffer is still useful: it lets the UI begin speaking the first
/// sentence while the FlutterTts engine warms up for the rest.
class StreamingTtsBuffer {
  StreamingTtsBuffer(this._tts);
  final FlutterTts _tts;

  final StringBuffer _pending = StringBuffer();
  bool _disposed = false;

  /// Push more tokens. Any complete sentences are spoken immediately.
  Future<void> add(String chunk) async {
    if (_disposed || chunk.isEmpty) return;
    _pending.write(chunk);
    await _drainSentences();
  }

  /// Speak whatever remains, even without terminal punctuation.
  Future<void> flush() async {
    if (_disposed) return;
    final remainder = _pending.toString().trim();
    _pending.clear();
    if (remainder.isNotEmpty) {
      await _tts.speak(remainder);
    }
  }

  /// Stop in-progress playback and discard buffered text. Safe to call from
  /// dispose paths.
  Future<void> cancel() async {
    _pending.clear();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _pending.clear();
  }

  Future<void> _drainSentences() async {
    while (true) {
      final text = _pending.toString();
      final cut = _findBoundary(text);
      if (cut < 0) return;
      final sentence = text.substring(0, cut + 1).trim();
      final rest = text.substring(cut + 1);
      _pending
        ..clear()
        ..write(rest);
      if (sentence.isNotEmpty) {
        await _tts.speak(sentence);
      }
    }
  }

  /// Returns the index of the rightmost-most-recent sentence terminator we
  /// should cut at, or -1 if none. We pick the first occurrence so chunks
  /// flow out as soon as possible.
  int _findBoundary(String s) {
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '.' || ch == '!' || ch == '?' || ch == '\n') {
        // Avoid breaking on common abbreviations: ".5", "Mr.", "U.S." — we
        // only split when followed by whitespace or end-of-string.
        final next = i + 1 < s.length ? s[i + 1] : ' ';
        if (next == ' ' || next == '\n' || i + 1 == s.length) {
          return i;
        }
      }
    }
    return -1;
  }
}
