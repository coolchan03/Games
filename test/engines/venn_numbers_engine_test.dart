import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/venn_numbers/venn_numbers_engine.dart';

void main() {
  group('VennNumbersEngine', () {
    late VennNumbersEngine engine;

    setUp(() {
      engine = VennNumbersEngine();
    });

    test('generateProblem returns a VennProblem with valid fields', () {
      final problem = engine.generateProblem();
      expect(problem.number, greaterThan(0));
      expect(problem.number, lessThanOrEqualTo(100));
      expect(problem.ruleA, isA<VennRule>());
      expect(problem.ruleB, isA<VennRule>());
      expect(problem.correctRegion, isA<VennRegion>());
    });

    test('correctRegion matches rule evaluation', () {
      final problem = engine.generateProblem();
      bool inA = problem.ruleA.test(problem.number);
      bool inB = problem.ruleB.test(problem.number);

      VennRegion expected;
      if (inA && inB) {
        expected = VennRegion.both;
      } else if (inA) {
        expected = VennRegion.aOnly;
      } else if (inB) {
        expected = VennRegion.bOnly;
      } else {
        expected = VennRegion.neither;
      }

      expect(problem.correctRegion, expected);
    });

    test('generateProblem produces two distinct meaningful rules', () {
      for (var i = 0; i < 80; i++) {
        final problem = engine.generateProblem();
        expect(problem.ruleA.description, isNot(problem.ruleB.description));
        final regions = <VennRegion>{};
        for (var n = 1; n <= 100; n++) {
          final a = problem.ruleA.test(n);
          final b = problem.ruleB.test(n);
          regions.add(a ? (b ? VennRegion.both : VennRegion.aOnly)
              : (b ? VennRegion.bOnly : VennRegion.neither));
        }
        expect(regions, containsAll(VennRegion.values),
            reason: '${problem.ruleA.description} / ${problem.ruleB.description}');
      }
    });
  });

  group('MultiplesRule', () {
    test('identifies multiples correctly', () {
      final rule = MultiplesRule(3);
      expect(rule.test(9), isTrue);
      expect(rule.test(12), isTrue);
      expect(rule.test(7), isFalse);
      expect(rule.test(0), isTrue);
    });

    test('description includes factor', () {
      expect(MultiplesRule(5).description, contains('5'));
    });
  });

  group('PrimesRule', () {
    test('identifies primes correctly', () {
      final rule = PrimesRule();
      expect(rule.test(2), isTrue);
      expect(rule.test(3), isTrue);
      expect(rule.test(7), isTrue);
      expect(rule.test(1), isFalse);
      expect(rule.test(0), isFalse);
      expect(rule.test(4), isFalse);
      expect(rule.test(9), isFalse);
    });
  });

  group('EvenOddRule', () {
    test('even rule works', () {
      final rule = EvenOddRule(even: true);
      expect(rule.test(2), isTrue);
      expect(rule.test(3), isFalse);
    });

    test('odd rule works', () {
      final rule = EvenOddRule(even: false);
      expect(rule.test(3), isTrue);
      expect(rule.test(2), isFalse);
    });
  });

  group('PerfectSquareRule', () {
    test('identifies perfect squares', () {
      final rule = PerfectSquareRule();
      expect(rule.test(4), isTrue);
      expect(rule.test(9), isTrue);
      expect(rule.test(16), isTrue);
      expect(rule.test(5), isFalse);
      expect(rule.test(7), isFalse);
    });
  });

  group('ComparisonRule', () {
    test('greater than works', () {
      final rule = ComparisonRule(10, greater: true);
      expect(rule.test(11), isTrue);
      expect(rule.test(9), isFalse);
    });

    test('less than works', () {
      final rule = ComparisonRule(10, greater: false);
      expect(rule.test(9), isTrue);
      expect(rule.test(11), isFalse);
    });
  });
}
