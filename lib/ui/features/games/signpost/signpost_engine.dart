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

/// Player state: successor links between cells.
class SignpostGame {
  SignpostGame(this.puzzle);
  final SignpostPuzzle puzzle;
  late final List<int?> next = List.filled(puzzle.n, null);
  final List<List<int?>> _history = [];

  bool canLink(int a, int b) {
    if (a < 0 || b < 0 || a >= puzzle.n || b >= puzzle.n || a == b ||
        puzzle.arrows[a] < 0 ||
        !puzzle.ray(a, puzzle.arrows[a]).contains(b)) return false;
    // The first clue cannot have a predecessor; two adjacent clue cells
    // must also have consecutive numbers.
    if (puzzle.clues[b] == 0) return false;
    final fromClue = puzzle.clues[a], toClue = puzzle.clues[b];
    if (fromClue != null && toClue != null && toClue != fromClue + 1) {
      return false;
    }
    if (next[a] == b) return true;
    // Never allow an arrow chain to close into a cycle.
    final visited = <int>{};
    int? cursor = b;
    while (cursor != null) {
      if (cursor == a || !visited.add(cursor)) return false;
      cursor = next[cursor];
    }
    return true;
  }

  void link(int a, int b) {
    if (!canLink(a, b) || next[a] == b) return;
    _history.add(List<int?>.of(next));
    // Remove any existing link into b.
    for (var i = 0; i < next.length; i++) {
      if (next[i] == b) next[i] = null;
    }
    next[a] = b;
  }

  void unlink(int a) {
    if (a < 0 || a >= puzzle.n || next[a] == null) return;
    _history.add(List<int?>.of(next));
    next[a] = null;
  }

  bool get canUndo => _history.isNotEmpty;
  void undo() {
    if (!canUndo) return;
    next.setAll(0, _history.removeLast());
  }

  void clearLinks() {
    if (next.every((link) => link == null)) return;
    _history.add(List<int?>.of(next));
    next.fillRange(0, next.length, null);
  }

  List<int> snapshot() => [for (final link in next) link ?? -1];

  /// Reject malformed or cyclic offline saves without damaging the game.
  bool restore(List<int> links) {
    if (links.length != puzzle.n) return false;
    final previous = List<int?>.of(next);
    next.fillRange(0, next.length, null);
    for (var i = 0; i < links.length; i++) {
      if (links[i] == -1) continue;
      if (!canLink(i, links[i]) || next.contains(links[i])) {
        next.setAll(0, previous);
        return false;
      }
      next[i] = links[i];
    }
    _history.clear();
    return true;
  }

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
    // Number labels alone are not sufficient. Every square must belong to
    // one actual, directed chain from the numbered start to the final star.
    final start = puzzle.clues.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .firstOrNull;
    if (start == null) return false;
    final visited = <int>{};
    var cell = start;
    for (var position = 0; position < puzzle.n; position++) {
      if (!visited.add(cell)) return false;
      final given = puzzle.clues[cell];
      if (given != null && given != position) return false;
      if (position == puzzle.n - 1) {
        return next[cell] == null && puzzle.arrows[cell] == -1 &&
            visited.length == puzzle.n;
      }
      final following = next[cell];
      if (following == null || following < 0 || following >= puzzle.n ||
          puzzle.arrows[cell] < 0 ||
          !puzzle.ray(cell, puzzle.arrows[cell]).contains(following)) {
        return false;
      }
      cell = following;
    }
    return false;
  }
}
