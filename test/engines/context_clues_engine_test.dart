import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/context_clues/context_clues_engine.dart';

void main() {
  group('ContextCluesEngine', () {
    late ContextCluesEngine engine;

    setUp(() {
      engine = ContextCluesEngine();
    });

    group('generateQuestionsForLevel', () {
      test('returns a non-empty list', () {
        final questions = engine.generateQuestionsForLevel(1);
        expect(questions, isNotEmpty);
      });

      test('returns questions with all fields', () {
        final questions = engine.generateQuestionsForLevel(1);
        for (final q in questions) {
          expect(q.sentence, isNotEmpty);
          expect(q.clue, isNotEmpty);
          expect(q.correctWord, isNotEmpty);
          expect(q.options.length, 4);
        }
      });

      test('correctWord is in options', () {
        final questions = engine.generateQuestionsForLevel(1);
        for (final q in questions) {
          expect(q.options, contains(q.correctWord));
        }
      });

      test('options vary across repeated shuffles', () {
        // Two independent shuffles can legitimately match (1 in 24 chance).
        // Sampling several deals avoids a nondeterministic CI failure.
        final orders = <String>{};
        for (var i = 0; i < 24; i++) {
          orders.add(engine.generateQuestionsForLevel(1).first.options.join('|'));
        }
        expect(orders.length, greaterThan(1));
      });

      test('returns all questions from pool', () {
        final questions = engine.generateQuestionsForLevel(1);
        expect(questions.length, greaterThanOrEqualTo(50));
      });
    });

    group('validateAnswer', () {
      test('returns true for correct answer', () {
        final questions = engine.generateQuestionsForLevel(1);
        final q = questions.first;
        expect(engine.validateAnswer(q, q.correctWord), isTrue);
      });

      test('returns true case insensitive', () {
        final questions = engine.generateQuestionsForLevel(1);
        final q = questions.first;
        expect(engine.validateAnswer(q, q.correctWord.toUpperCase()), isTrue);
      });

      test('returns false for wrong answer', () {
        final questions = engine.generateQuestionsForLevel(1);
        final q = questions.first;
        expect(engine.validateAnswer(q, 'wronganswer'), isFalse);
      });
    });
  });

  group('ClueQuestion', () {
    test('stores all fields', () {
      const q = ClueQuestion(
        sentence: 'The cat is ___.',
        clue: 'A feline.',
        correctWord: 'cat',
        options: ['cat', 'dog', 'bird', 'fish'],
      );
      expect(q.sentence, 'The cat is ___.');
      expect(q.correctWord, 'cat');
      expect(q.options.length, 4);
    });
  });
}
