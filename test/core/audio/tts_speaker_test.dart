import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/audio/tts_speaker.dart';

void main() {
  group('TtsSpeaker.sanitize', () {
    test('strips parenthetical and bracketed annotations', () {
      expect(
        TtsSpeaker.sanitize('run (koşmak) [verb]'),
        'run',
      );
    });

    test('keeps apostrophes and hyphens', () {
      expect(
        TtsSpeaker.sanitize("don't give up — it's a well-known phrase!"),
        "don't give up  it's a well-known phrase",
      );
    });

    test('removes non-ASCII symbols TTS cannot pronounce', () {
      expect(TtsSpeaker.sanitize('café ☕ 100%'), 'caf  100');
    });

    test('returns empty string when nothing speakable remains', () {
      expect(TtsSpeaker.sanitize('(...) [!!]'), '');
    });
  });
}
