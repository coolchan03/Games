import 'dart:math';

import '../common/level_kit.dart';

/// Exact Lights Out maths over GF(2). A position (n x n, row-major) is
/// solvable iff a set of presses exists whose combined effect equals it. This
/// gives a *proof* of solvability, the minimum press count (used as par) and a
/// perfect hint. Plain lists are used instead of bit tricks so it behaves the
/// same on the web build.
class LightsOutSolver {
  /// Effect of pressing cell [i] on an [n]x[n] board.
  static List<int> _effect(int n, int i) {
    final r = i ~/ n, c = i % n;
    return [
      i,
      if (r > 0) i - n,
      if (r < n - 1) i + n,
      if (c > 0) i - 1,
      if (c < n - 1) i + 1,
    ];
  }

  /// A minimum set of cells to press to switch every light off, or null when
  /// the position cannot be cleared.
  static List<int>? solve(int n, List<bool> lights) {
    final cells = n * n;
    // Augmented matrix: A x = b, columns 0..cells-1 and the target at `cells`.
    final rows = [
      for (var cell = 0; cell < cells; cell++) List<int>.filled(cells + 1, 0),
    ];
    for (var press = 0; press < cells; press++) {
      for (final affected in _effect(n, press)) {
        rows[affected][press] = 1;
      }
    }
    for (var cell = 0; cell < cells; cell++) {
      rows[cell][cells] = lights[cell] ? 1 : 0;
    }
    final pivotOfColumn = <int, int>{};
    var rank = 0;
    for (var col = 0; col < cells && rank < cells; col++) {
      var pivot = -1;
      for (var r = rank; r < cells; r++) {
        if (rows[r][col] == 1) {
          pivot = r;
          break;
        }
      }
      if (pivot < 0) continue;
      final tmp = rows[rank];
      rows[rank] = rows[pivot];
      rows[pivot] = tmp;
      for (var r = 0; r < cells; r++) {
        if (r != rank && rows[r][col] == 1) {
          for (var k = col; k <= cells; k++) {
            rows[r][k] ^= rows[rank][k];
          }
        }
      }
      pivotOfColumn[col] = rank;
      rank++;
    }
    // Inconsistent rows (0 = 1) mean the position is unreachable.
    for (var r = rank; r < cells; r++) {
      if (rows[r][cells] == 1) return null;
    }
    final free = [for (var c = 0; c < cells; c++) if (!pivotOfColumn.containsKey(c)) c];
    List<int>? best;
    for (var mask = 0; mask < (1 << free.length); mask++) {
      final x = List<int>.filled(cells, 0);
      for (var k = 0; k < free.length; k++) {
        x[free[k]] = (mask >> k) & 1;
      }
      pivotOfColumn.forEach((col, row) {
        var v = rows[row][cells];
        for (final f in free) {
          if (rows[row][f] == 1) v ^= x[f];
        }
        x[col] = v;
      });
      final presses = [for (var c = 0; c < cells; c++) if (x[c] == 1) c];
      if (best == null || presses.length < best.length) best = presses;
    }
    return best;
  }

  static bool isSolvable(int n, List<bool> lights) => solve(n, lights) != null;

  static List<bool> press(int n, List<bool> lights, int cell) {
    final next = [...lights];
    for (final a in _effect(n, cell)) {
      next[a] = !next[a];
    }
    return next;
  }
}

class LightsOutLevel {
  const LightsOutLevel(this.size, this.lights, this.par, this.seed);
  final int size;
  final List<bool> lights;

  /// Fewest presses that clear the board.
  final int par;
  final int seed;
}

class LightsOutLevels {
  static const int count = 20;

  /// 3x3 for levels 1-3, 4x4 for 4-7, 5x5 for 8-13, 6x6 for 14-17, 7x7 for 18+.
  static int sizeFor(int level) =>
      level <= 3 ? 3 : level <= 7 ? 4 : level <= 13 ? 5 : level <= 17 ? 6 : 7;

  static String describe(int level) => '${sizeFor(level)}×${sizeFor(level)}';

  static LightsOutLevel build(int level) =>
      _generate(levelSeed('lights_out', level), level);

  static LightsOutLevel random(int level, [Random? random]) =>
      _generate(randomLevelSeed(random), level);

  static LightsOutLevel _generate(int seed, int level) {
    final n = sizeFor(level);
    final cells = n * n;
    // More presses scrambled in as the level number rises.
    final presses = min(cells - 1, 2 + level ~/ 2 + n);
    final made = generateVerified<LightsOutLevel>(
      seed: seed,
      make: (random) {
        var lights = List<bool>.filled(cells, false);
        final chosen = <int>{};
        while (chosen.length < presses) {
          chosen.add(random.nextInt(cells));
        }
        for (final cell in chosen) {
          lights = LightsOutSolver.press(n, lights, cell);
        }
        final solution = LightsOutSolver.solve(n, lights);
        return LightsOutLevel(n, lights, solution?.length ?? 0, seed);
      },
      // Must be provably solvable and genuinely need several presses.
      verify: (l) => l.par >= min(3, presses) && l.lights.any((on) => on),
    );
    return made ?? _fallback(n, seed);
  }

  static LightsOutLevel _fallback(int n, int seed) {
    var lights = List<bool>.filled(n * n, false);
    for (final cell in [0, n + 1, 2 * n + 2]) {
      lights = LightsOutSolver.press(n, lights, cell);
    }
    return LightsOutLevel(n, lights, LightsOutSolver.solve(n, lights)!.length, seed);
  }
}

/// Position graph for tests / generic tooling: states are light patterns.
class LightsOutPuzzle extends SearchPuzzle<List<bool>> {
  LightsOutPuzzle(this.n);
  final int n;
  @override
  String key(List<bool> s) => s.map((b) => b ? '1' : '0').join();
  @override
  bool isGoal(List<bool> s) => !s.any((b) => b);
  @override
  Iterable<List<bool>> successors(List<bool> s) sync* {
    for (var i = 0; i < n * n; i++) {
      yield LightsOutSolver.press(n, s, i);
    }
  }
}
