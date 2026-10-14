import 'dart:math';

enum VennRegion {
  aOnly,
  bOnly,
  both,
  neither,
}

abstract class VennRule {
  String get description;
  bool test(int n);
}

class MultiplesRule extends VennRule {
  final int factor;
  MultiplesRule(this.factor);
  @override
  String get description => "Multiples of $factor";
  @override
  bool test(int n) => n % factor == 0;
}

class PrimesRule extends VennRule {
  @override
  String get description => "Prime Numbers";
  @override
  bool test(int n) {
    if (n < 2) return false;
    for (int i = 2; i <= sqrt(n).toInt(); i++) {
      if (n % i == 0) return false;
    }
    return true;
  }
}

class EvenOddRule extends VennRule {
  final bool even;
  EvenOddRule({required this.even});
  @override
  String get description => even ? "Even Numbers" : "Odd Numbers";
  @override
  bool test(int n) => even ? n % 2 == 0 : n % 2 != 0;
}

class PerfectSquareRule extends VennRule {
  @override
  String get description => "Perfect Squares";
  @override
  bool test(int n) {
    int s = sqrt(n).toInt();
    return s * s == n;
  }
}

class ComparisonRule extends VennRule {
  final int threshold;
  final bool greater;
  ComparisonRule(this.threshold, {required this.greater});
  @override
  String get description => greater ? "Greater than $threshold" : "Less than $threshold";
  @override
  bool test(int n) => greater ? n > threshold : n < threshold;
}

class VennProblem {
  final int number;
  final VennRule ruleA;
  final VennRule ruleB;
  final VennRegion correctRegion;

  VennProblem({
    required this.number,
    required this.ruleA,
    required this.ruleB,
    required this.correctRegion,
  });
}

class VennNumbersEngine {
  final Random _random = Random();

  VennProblem generateProblem() {
    final rules = _getTwoDistinctRules();
    final ruleA = rules[0];
    final ruleB = rules[1];

    // Choose a target region first, then sample from its actual members.
    // No 50-attempt fallback: every generated puzzle matches its target.
    final region = VennRegion.values[_random.nextInt(4)];
    final candidates = [
      for (var n = 1; n <= 100; n++)
        if (_region(ruleA, ruleB, n) == region) n,
    ];
    final number = candidates[_random.nextInt(candidates.length)];
    return VennProblem(
      number: number,
      ruleA: ruleA,
      ruleB: ruleB,
      correctRegion: region,
    );
  }

  VennRegion _region(VennRule a, VennRule b, int n) {
    final inA = a.test(n);
    final inB = b.test(n);
    if (inA) return inB ? VennRegion.both : VennRegion.aOnly;
    return inB ? VennRegion.bOnly : VennRegion.neither;
  }

  List<VennRule> _getTwoDistinctRules() {
    final allRules = [
      MultiplesRule(2),
      MultiplesRule(3),
      MultiplesRule(5),
      PrimesRule(),
      EvenOddRule(even: true),
      EvenOddRule(even: false),
      PerfectSquareRule(),
      ComparisonRule(20, greater: true),
      ComparisonRule(50, greater: false),
    ];
    
    allRules.shuffle(_random);
    // Avoid equivalent or mutually exclusive rule pairs. Every region
    // should have at least one valid answer from the displayed 1..100 range.
    for (var i = 0; i < allRules.length; i++) {
      for (var j = i + 1; j < allRules.length; j++) {
        final a = allRules[i], b = allRules[j];
        if (a.description == b.description) continue;
        final found = <VennRegion>{};
        for (var n = 1; n <= 100 && found.length < 4; n++) {
          found.add(_region(a, b, n));
        }
        if (found.length == 4) return [a, b];
      }
    }
    throw StateError('No meaningful Venn rule pairs found');
  }
}
