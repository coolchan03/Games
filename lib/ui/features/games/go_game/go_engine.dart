import 'dart:math';

/// Go with captures, no suicide, simple ko, passing and area (Chinese/
/// Tromp-Taylor) scoring with komi.
class GoBoard {
  GoBoard(this.n) : cells = List.filled(n * n, 0);
  GoBoard._(this.n, this.cells, this.turn, this.ko, this.passes, this.captures);

  final int n;
  final List<int> cells;
  int turn = 1; // 1 black, 2 white
  int? ko;
  int passes = 0;
  List<int> captures = [0, 0];

  GoBoard copy() => GoBoard._(n, List.of(cells), turn, ko, passes, List.of(captures));

  List<int> neighbours(int i) {
    final x = i % n, y = i ~/ n;
    return [
      if (x > 0) i - 1,
      if (x < n - 1) i + 1,
      if (y > 0) i - n,
      if (y < n - 1) i + n,
    ];
  }

  /// Group containing [i] and whether it has any liberty.
  (List<int>, bool) group(int i) {
    final c = cells[i];
    final stones = [i];
    final seen = {i};
    var liberty = false;
    for (var k = 0; k < stones.length; k++) {
      for (final m in neighbours(stones[k])) {
        if (cells[m] == 0) {
          liberty = true;
        } else if (cells[m] == c && seen.add(m)) {
          stones.add(m);
        }
      }
    }
    return (stones, liberty);
  }

  bool isLegal(int i) {
    if (cells[i] != 0 || i == ko) return false;
    cells[i] = turn;
    var ok = group(i).$2;
    if (!ok) {
      // Legal if it captures something.
      for (final m in neighbours(i)) {
        if (cells[m] == 3 - turn && !group(m).$2) {
          ok = true;
          break;
        }
      }
    }
    cells[i] = 0;
    return ok;
  }

  bool play(int i) {
    if (!isLegal(i)) return false;
    cells[i] = turn;
    final captured = <int>[];
    for (final m in neighbours(i)) {
      if (cells[m] == 3 - turn) {
        final (stones, lib) = group(m);
        if (!lib) {
          for (final s in stones) {
            cells[s] = 0;
          }
          captured.addAll(stones);
        }
      }
    }
    captures[turn - 1] += captured.length;
    // Simple ko: single stone captured by a single stone with one liberty.
    final own = group(i);
    ko = captured.length == 1 && own.$1.length == 1 && neighbours(i).where((m) => cells[m] == 0).length == 1
        ? captured.first
        : null;
    passes = 0;
    turn = 3 - turn;
    return true;
  }

  void pass() {
    passes++;
    ko = null;
    turn = 3 - turn;
  }

  bool get over => passes >= 2;

  /// Area score: stones plus empty regions bordered by one colour only.
  (double, double) score(double komi) {
    var b = 0.0, w = komi;
    final seen = List.filled(n * n, false);
    for (var i = 0; i < n * n; i++) {
      if (cells[i] == 1) b++;
      if (cells[i] == 2) w++;
      if (cells[i] != 0 || seen[i]) continue;
      final region = [i];
      seen[i] = true;
      final borders = <int>{};
      for (var k = 0; k < region.length; k++) {
        for (final m in neighbours(region[k])) {
          if (cells[m] == 0 && !seen[m]) {
            seen[m] = true;
            region.add(m);
          } else if (cells[m] != 0) {
            borders.add(cells[m]);
          }
        }
      }
      if (borders.length == 1) {
        if (borders.first == 1) {
          b += region.length;
        } else {
          w += region.length;
        }
      }
    }
    return (b, w);
  }

  /// A point surrounded by the player's own stones (a simple eye).
  bool _isOwnEye(int i, int p) => cells[i] == 0 && neighbours(i).every((m) => cells[m] == p);

  /// Random playout to the end; returns the winner (1 or 2).
  int _playout(Random rng, double komi) {
    var moves = 0;
    final limit = n * n * 3;
    final order = List.generate(n * n, (i) => i);
    while (moves++ < limit && passes < 2) {
      order.shuffle(rng);
      var played = false;
      for (final i in order) {
        if (cells[i] != 0 || _isOwnEye(i, turn)) continue;
        if (play(i)) {
          played = true;
          break;
        }
      }
      if (!played) pass();
    }
    final (b, w) = score(komi);
    return b > w ? 1 : 2;
  }

  /// Flat Monte Carlo move selection; returns -1 to pass.
  int aiMove(int playouts, Random rng, double komi, {int timeMs = 1500}) {
    final me = turn;
    final candidates = [
      for (var i = 0; i < n * n; i++)
        if (cells[i] == 0 && !_isOwnEye(i, me) && isLegal(i)) i
    ];
    if (candidates.isEmpty) return -1;
    final wins = List.filled(n * n, 0), tries = List.filled(n * n, 0);
    final sw = Stopwatch()..start();
    for (var k = 0; k < playouts && sw.elapsedMilliseconds < timeMs; k++) {
      final i = candidates[k % candidates.length];
      final b = copy()..play(i);
      tries[i]++;
      if (b._playout(rng, komi) == me) wins[i]++;
    }
    var best = -1;
    var bestRate = -1.0;
    for (final i in candidates) {
      if (tries[i] == 0) continue;
      final r = wins[i] / tries[i];
      if (r > bestRate) {
        bestRate = r;
        best = i;
      }
    }
    // Pass when every move looks hopeless or the opponent just passed and
    // we are ahead.
    final (b, w) = score(komi);
    final ahead = me == 1 ? b > w : w > b;
    if (passes == 1 && ahead) return -1;
    if (bestRate < .05) return -1;
    return best;
  }
}
