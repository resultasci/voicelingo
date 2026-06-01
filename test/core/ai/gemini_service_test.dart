import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/ai/gemini_service.dart';

void main() {
  group('bcp47ForTargetLanguage', () {
    test('known ISO-639-1 codes pass through', () {
      expect(bcp47ForTargetLanguage('en'), 'en');
      expect(bcp47ForTargetLanguage('tr'), 'tr');
      expect(bcp47ForTargetLanguage('de'), 'de');
    });

    test('uppercase normalized to lowercase', () {
      expect(bcp47ForTargetLanguage('EN'), 'en');
      expect(bcp47ForTargetLanguage('Tr'), 'tr');
    });

    test('unknown codes return null', () {
      expect(bcp47ForTargetLanguage('xx'), isNull);
      expect(bcp47ForTargetLanguage('klingon'), isNull);
    });

    test('null and empty return null', () {
      expect(bcp47ForTargetLanguage(null), isNull);
      expect(bcp47ForTargetLanguage(''), isNull);
      expect(bcp47ForTargetLanguage('   '), isNull);
    });
  });

  group('SpeechEvaluation.fromJson', () {
    test('coerces int score from various types', () {
      final fromInt = SpeechEvaluation.fromJson({'correct': 'a', 'score': 80});
      expect(fromInt.score, 80);

      final fromDouble =
          SpeechEvaluation.fromJson({'correct': 'a', 'score': 80.4});
      expect(fromDouble.score, 80);

      final fromString =
          SpeechEvaluation.fromJson({'correct': 'a', 'score': '90'});
      expect(fromString.score, 90);

      final missing = SpeechEvaluation.fromJson({'correct': 'a'});
      expect(missing.score, 0);
    });

    test('grammar_errors defaults to empty list when missing', () {
      final e = SpeechEvaluation.fromJson({'correct': 'a'});
      expect(e.grammarErrors, isEmpty);
    });

    test('grammar_errors filters non-strings out', () {
      final e = SpeechEvaluation.fromJson({
        'correct': 'a',
        'grammar_errors': ['wrong tense', 42, null, 'missing article'],
      });
      expect(e.grammarErrors, ['wrong tense', 'missing article']);
    });
  });

  group('AiException', () {
    test('isRateLimit + isAuth flags', () {
      expect(AiException(429, 'limit').isRateLimit, isTrue);
      expect(AiException(401, 'auth').isAuth, isTrue);
      expect(AiException(500, 'oops').isRateLimit, isFalse);
      expect(AiException(500, 'oops').isAuth, isFalse);
    });
  });
}
