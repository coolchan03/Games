import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_kit.dart';

/// Walk from 0 to [goal] by +1 or +3; states above [limit] do not exist. Parity
/// tricks make some starts unreachable, which exercises trap detection.
class _Counter extends SearchPuzzle<int> {
  _Counter(this.goal, this.limit, {this.steps = const [1, 3]});
  final int goal, limit;
  final List<int> steps;
  @override
  String key(int s) => '$s';
  @override
  bool isGoal(int s) => s == goal;
  @override
  Iterable<int> successors(int s) =>
      [for (final d in steps) if (s + d <= limit) s + d];
}

void main() {
  test('finds the shortest path', () {
    final r = solvePuzzle(_Counter(10, 12), 0);
    expect(r.status, Solvability.solvable);
    expect(r.moves, 4); // 3+3+3+1
    expect(r.path.first, 0);
    expect(r.path.last, 10);
  });

  test('exhausting the space proves a position lost', () {
    final r = solvePuzzle(_Counter(5, 8, steps: const [2]), 0);
    expect(r.status, Solvability.unsolvable); // only even numbers
  });

  test('a tiny budget is inconclusive, never "trapped"', () {
    final puzzle = _Counter(500, 600, steps: const [1]);
    final monitor = TrapMonitor(puzzle, maxNodes: 10);
    expect(monitor.analyze(0), Solvability.unknown);
    expect(monitor.isTrapped(0), isFalse);
    expect(monitor.hint(0), isNull);
  });

  test('monitor reports traps and hints only from winnable positions', () {
    final monitor = TrapMonitor(_Counter(10, 12));
    expect(monitor.isTrapped(0), isFalse);
    expect(monitor.hint(0), anyOf(1, 3)); // both start a 4-move line
    expect(monitor.isTrapped(11), isTrue); // overshot: 11 -> 12 only
    expect(monitor.hint(11), isNull);
    expect(monitor.hint(10), isNull); // already won
  });

  test('seeds are stable and distinct per level', () {
    expect(levelSeed('water_sort', 3), levelSeed('water_sort', 3));
    expect({for (var i = 1; i <= 50; i++) levelSeed('water_sort', i)}.length, 50);
    expect(levelSeed('a', 1), isNot(levelSeed('b', 1)));
    expect(levelDifficulty(1, 30), 0);
    expect(levelDifficulty(30, 30), 1);
  });

  test('generateVerified skips unwinnable candidates', () {
    final level = generateVerified<int>(
      seed: 1,
      make: (r) => r.nextInt(12),
      verify: (start) => !solvePuzzle(_Counter(10, 12, steps: const [2]), start).moves.isNull,
    );
    expect(level!.isEven, isTrue);
  });
}

extension on int? {
  bool get isNull => this == null;
}
