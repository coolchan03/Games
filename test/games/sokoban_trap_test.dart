import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_kit.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_analysis.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_engine.dart';

/// Hand-made 7x5 room (walls outside): goal at the middle of the right side.
SokobanLevel room({required Set<int> boxes, int player = 8}) {
  const w = 7, h = 5;
  final walls = <int>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (x == 0 || y == 0 || x == w - 1 || y == h - 1) walls.add(y * w + x);
    }
  }
  return SokobanLevel(w, h, walls, {2 * w + 5}, boxes, player, 0);
}

void main() {
  test('a box in a corner is a proven deadlock; a box in the open is not', () {
    final corner = room(boxes: {1 * 7 + 1});
    expect(SokobanAnalysis(corner).trapped(corner.boxes), isTrue);
    final open = room(boxes: {2 * 7 + 3});
    expect(SokobanAnalysis(open).trapped(open.boxes), isFalse);
  });

  test('a box pushed against a wall with no goal along it is dead', () {
    // Top wall row has no goal: any box on y == 1 can never leave it.
    final level = room(boxes: {1 * 7 + 3});
    expect(SokobanAnalysis(level).trapped(level.boxes), isTrue);
  });

  test('two boxes side by side against a wall freeze each other', () {
    final level = room(boxes: {3 * 7 + 2, 3 * 7 + 3}); // bottom row next to the wall
    // Both rest on the row above the bottom wall: neither can be pushed up.
    expect(SokobanAnalysis(level).trapped(level.boxes), isTrue);
  });

  test('never reports a trap on any state along a real solution (soundness)', () {
    for (var seed = 1; seed <= 25; seed++) {
      final level = SokobanLevel.generate(seed, size: 6, boxCount: 2);
      final analysis = SokobanAnalysis(level);
      final start = (boxes: Set<int>.of(level.boxes), player: level.player);
      final result = solvePuzzle(SokobanPuzzle(level), start, maxNodes: 60000);
      if (result.status != Solvability.solvable) continue; // too big for the test budget
      for (final state in result.path) {
        expect(analysis.trapped(state.boxes), isFalse,
            reason: 'seed $seed state ${state.boxes}');
      }
    }
  });

  test('generated levels are winnable and are not trapped at the start', () {
    var proven = 0;
    for (var seed = 1; seed <= 25; seed++) {
      final level = SokobanLevel.generate(seed, size: 6, boxCount: 2);
      expect(SokobanAnalysis(level).trapped(level.boxes), isFalse, reason: 'seed $seed');
      final r = solvePuzzle(SokobanPuzzle(level),
          (boxes: Set<int>.of(level.boxes), player: level.player),
          maxNodes: 60000);
      expect(r.status, isNot(Solvability.unsolvable), reason: 'seed $seed');
      if (r.status == Solvability.solvable) proven++;
    }
    expect(proven, greaterThan(15));
  });
}
