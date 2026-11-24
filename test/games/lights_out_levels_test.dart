import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_kit.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_levels.dart';

void main() {
  test('GF(2) solver clears boards and finds a true minimum', () {
    // Pressing one cell then solving must give back at most that one press.
    for (final n in [3, 4, 5, 6, 7]) {
      for (var cell = 0; cell < n * n; cell += 3) {
        final lights = LightsOutSolver.press(n, List.filled(n * n, false), cell);
        final solution = LightsOutSolver.solve(n, lights)!;
        expect(solution.length, 1, reason: '$n cell $cell');
        var board = lights;
        for (final c in solution) {
          board = LightsOutSolver.press(n, board, c);
        }
        expect(board.any((b) => b), isFalse);
      }
    }
  });

  test('knows that some 5x5 positions can never be cleared', () {
    // A single lit corner on 5x5 is a classic unsolvable pattern.
    final lone = List<bool>.filled(25, false)..[0] = true;
    expect(LightsOutSolver.isSolvable(5, lone), isFalse);
    // ...whereas 3x3 is fully solvable from any position.
    final random = Random(5);
    for (var i = 0; i < 50; i++) {
      expect(LightsOutSolver.isSolvable(3, [for (var k = 0; k < 9; k++) random.nextBool()]), isTrue);
    }
  });

  test('solver agrees with brute-force BFS on small boards', () {
    final random = Random(9);
    for (var i = 0; i < 30; i++) {
      final lights = [for (var k = 0; k < 16; k++) random.nextBool()];
      final fast = LightsOutSolver.solve(4, lights);
      final slow = solvePuzzle(LightsOutPuzzle(4), lights, maxNodes: 70000);
      if (fast == null) {
        expect(slow.status, Solvability.unsolvable);
      } else {
        expect(slow.moves, fast.length, reason: '4x4 case $i');
      }
    }
  });

  test('all 20 levels and 60 random levels are solvable, non-trivial and sized right', () {
    for (var l = 1; l <= LightsOutLevels.count; l++) {
      final level = LightsOutLevels.build(l);
      expect(level.size, LightsOutLevels.sizeFor(l));
      expect(level.lights.length, level.size * level.size);
      final solution = LightsOutSolver.solve(level.size, level.lights);
      expect(solution, isNotNull, reason: 'level $l');
      expect(solution!.length, level.par);
      expect(level.par, greaterThanOrEqualTo(3));
      expect(LightsOutLevels.build(l).lights, level.lights); // deterministic
    }
    final random = Random(2);
    for (var i = 0; i < 60; i++) {
      final level = LightsOutLevels.random(1 + random.nextInt(20), random);
      expect(LightsOutSolver.isSolvable(level.size, level.lights), isTrue);
    }
  });
}
