import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/features/grammar/models/grammar_topic.dart';

void main() {
  group('GrammarTopic round-trip', () {
    const topic = GrammarTopic(
      id: 'id-1',
      level: 'A1',
      orderIndex: 3,
      code: 'present_simple',
      titleTr: 'Geniş Zaman',
      titleEn: 'Present Simple',
      descriptionTr: 'Açıklama',
      descriptionEn: 'Description',
      examples: [
        TopicExample(en: 'I work', tr: 'Ben çalışırım'),
        TopicExample(en: 'She runs', tr: 'O koşar'),
      ],
      quiz: [
        QuizQuestion(
          type: 'mc',
          promptEn: 'She ___ to school.',
          promptTr: 'O okula ___.',
          options: ['go', 'goes', 'going'],
          answer: 'goes',
        ),
      ],
      xpReward: 45,
    );

    test('toMap → fromMap preserves all fields', () {
      final restored = GrammarTopic.fromMap(topic.toMap());

      expect(restored.id, topic.id);
      expect(restored.level, topic.level);
      expect(restored.orderIndex, topic.orderIndex);
      expect(restored.code, topic.code);
      expect(restored.titleTr, topic.titleTr);
      expect(restored.titleEn, topic.titleEn);
      expect(restored.descriptionTr, topic.descriptionTr);
      expect(restored.descriptionEn, topic.descriptionEn);
      expect(restored.xpReward, topic.xpReward);
      expect(restored.examples.length, 2);
      expect(restored.examples.first.en, 'I work');
      expect(restored.examples.first.tr, 'Ben çalışırım');
      expect(restored.quiz.single.type, 'mc');
      expect(restored.quiz.single.options, ['go', 'goes', 'going']);
      expect(restored.quiz.single.answer, 'goes');
    });

    test('survives Hive-style Map<dynamic, dynamic> nested maps', () {
      // Hive, iç içe map'leri Map<dynamic, dynamic> olarak geri döndürür;
      // fromMap bunu Map<String, dynamic>.from ile tolere etmeli.
      final map = topic.toMap();
      final hiveStyle = <String, dynamic>{
        ...map,
        'examples': (map['examples'] as List)
            .map((e) => Map<dynamic, dynamic>.from(e as Map))
            .toList(),
        'quiz_questions': (map['quiz_questions'] as List)
            .map((q) => Map<dynamic, dynamic>.from(q as Map))
            .toList(),
      };

      final restored = GrammarTopic.fromMap(hiveStyle);
      expect(restored.examples.length, 2);
      expect(restored.quiz.single.answer, 'goes');
    });

    test('fromMap tolerates missing optional fields', () {
      final restored = GrammarTopic.fromMap({
        'id': 'id-2',
        'level': 'A2',
        'order_index': 0,
        'code': 'past_simple',
        'title_tr': 'Geçmiş Zaman',
        'title_en': 'Past Simple',
      });

      expect(restored.descriptionTr, isNull);
      expect(restored.examples, isEmpty);
      expect(restored.quiz, isEmpty);
      expect(restored.xpReward, 30); // varsayılan
    });
  });
}
