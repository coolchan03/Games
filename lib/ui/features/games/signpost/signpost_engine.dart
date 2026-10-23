// Signpost, after Simon Tatham's Portable Puzzle Collection (signpost.c,
// MIT). Generator: random Hamiltonian path along queen moves, then number
// clues are revealed until a solver proves the path is unique.
import 'dart:math';

const signDirs = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)];

class SignpostPuzzle {
  SignpostPuzzle({this.w = 5, this.h = 5, Random? random}) : rng = random ?? Random() {
    _generate();
  }

  final int w, h;
  final Random rng;

  /// solution[k] = cell at position k (0-based).
  late List<int> solution;

  /// Arrow direction index for each cell (-1 for the final cell).
  late List<int> arrows;

  /// Revealed numbers (0-based position) for clue cells.
  final Map<int, int> clues = {};

  int get n => w * h;

  List<int> ray(int cell, int dir) {
    final (dx, dy) = signDirs[dir];
    var x = cell % w + dx, y = cell ~/ w + dy;
    final out = <int>[];
    while (x >= 0 && y >= 0 && x < w && y < h) {
      out.add(y * w + x);
      x += dx;
      y += dy;
    }
    return out;
  }

  int? dirBetween(int a, int b) {
    final dx = b % w - a % w, dy = b ~/ w - a ~/ w;
    if (dx == 0 && dy == 0) return null;
    if (dx != 0 && dy != 0 && dx.abs() != dy.abs()) return null;
    return signDirs.indexOf((dx.sign, dy.sign));
  }

  List<int>? _randomPath() {
    final visited = List.filled(n, false);
    final path = <int>[];
    var budget = 20000;
    List<int> nexts(int c) => [
          for (var d = 0; d < 8; d++)
            for (final x in ray(c, d))
              if (!visited[x]) x
        ];
    bool dfs(int c) {
      if (--budget < 0) return false;
      visited[c] = true;
      path.add(c);
      if (path.length == n) return true;
      final options = nexts(c)..shuffle(rng);
      // Warnsdorff: try cells with the fewest onward moves first.
      options.sort((a, b) => nexts(a).length.compareTo(nexts(b).length));
      for (final o in options) {
        if (dfs(o)) return true;
      }
      visited[c] = false;
      path.removeLast();
      return false;
    }

    return dfs(rng.nextInt(n)) ? path : null;
  }

  void _generate() {
    while (true) {
      final p = _randomPath();
      if (p == null) continue;
      solution = p;
      arrows = List.filled(n, -1);
      for (var k = 0; k + 1 < n; k++) {
        arrows[p[k]] = dirBetween(p[k], p[k + 1])!;
      }
      clues
        ..clear()
        ..[p.first] = 0
        ..[p.last] = n - 1;
      var guard = 0;
      while (countSolutions(limit: 2) != 1 && guard++ < n) {
        final hidden = [for (var k = 1; k < n - 1; k++) if (!clues.containsKey(p[k])) p[k]];
        final cell = hidden[rng.nextInt(hidden.length)];
        clues[cell] = solution.indexOf(cell);
      }
      if (countSolutions(limit: 2) == 1) return;
    }
  }

  /// Number of complete paths consistent with arrows and clues (capped).
  int countSolutions({int limit = 2, int budget = 200000}) {
    final byPos = <int, int>{for (final e in clues.entries) e.value: e.key};
    final start = byPos[0];
    if (start == null) return 0;
    final used = List.filled(n, false);
    var count = 0;
    var nodes = 0;
    void dfs(int cell, int pos) {
      if (count >= limit || ++nodes > budget) return;
      if (pos == n - 1) {
        count++;
        return;
      }
      final fixedNext = byPos[pos + 1];
      for (final c in ray(cell, arrows[cell])) {
        if (used[c]) continue;
        if (fixedNext != null && c != fixedNext) continue;
        final fixedPos = clues[c];
        if (fixedPos != null && fixedPos != pos + 1) continue;
        if (pos + 1 == n - 1 && arrows[c] != -1) continue;
        if (pos + 1 < n - 1 && arrows[c] == -1) continue;
        used[c] = true;
        dfs(c, pos + 1);
        used[c] = false;
      }
    }

    used[start] = true;
    dfs(start, 0);
    return nodes > budget ? limit : count;
  }
}

/// The 20 numbered Signpost levels: 4×4 (1–6), 5×5 (7–13), 6×6 (14–20).
/// Each level is generated from a fixed seed, so it is the same puzzle on
/// every device and always has exactly one solution.
class SignpostLevels {
  static int sizeFor(int level) => level <= 6 ? 4 : level <= 13 ? 5 : 6;

  static SignpostPuzzle build(int level) {
    final size = sizeFor(level);
    return SignpostPuzzle(w: size, h: size, random: Random(7100 + level * 37));
  }
}

/// Player state: successor links between cells.
class SignpostGame {
  SignpostGame(this.puzzle);
  final SignpostPuzzle puzzle;
  late final List<int?> next = List.filled(puzzle.n, null);

  bool canLink(int a, int b) =>
      a != b && puzzle.arrows[a] >= 0 && puzzle.ray(a, puzzle.arrows[a]).contains(b);

  void link(int a, int b) {
    if (!canLink(a, b)) return;
    // Remove any existing link into b.
    for (var i = 0; i < next.length; i++) {
      if (next[i] == b) next[i] = null;
    }
    next[a] = b;
  }

  void unlink(int a) => next[a] = null;

  int? prev(int b) {
    for (var i = 0; i < next.length; i++) {
      if (next[i] == b) return i;
    }
    return null;
  }

  /// Number shown on each cell (0-based) if its chain contains a clue.
  List<int?> numbers() {
    final out = List<int?>.filled(puzzle.n, null);
    for (final e in puzzle.clues.entries) {
      var c = e.key, k = e.value;
      final seen = <int>{};
      while (seen.add(c)) {
        out[c] = k;
        final nx = next[c];
        if (nx == null) break;
        c = nx;
        k++;
      }
      c = e.key;
      k = e.value;
      seen.clear();
      while (seen.add(c)) {
        out[c] = k;
        final p = prev(c);
        if (p == null) break;
        c = p;
        k--;
      }
    }
    return out;
  }

  bool get solved {
    final nums = numbers();
    for (var i = 0; i < puzzle.n; i++) {
      if (nums[i] == null) return false;
    }
    final order = List<int?>.filled(puzzle.n, null);
    for (var i = 0; i < puzzle.n; i++) {
      final k = nums[i]!;
      if (k < 0 || k >= puzzle.n || order[k] != null) return false;
      order[k] = i;
    }
    for (final e in puzzle.clues.entries) {
      if (nums[e.key] != e.value) return false;
    }
    return true;
  }
}
