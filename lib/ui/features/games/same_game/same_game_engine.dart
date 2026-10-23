// Same Game rules and scoring as in Simon Tatham's Portable Puzzle
// Collection (samegame.c, MIT). The solvable-board generator follows the
// same idea as samegame.c's gen_grid — build the board backwards by inserting
// two-cell blobs that do not touch their own colour — in a simplified form.
import 'dart:math';

class SameGame {
  SameGame({this.w = 10, this.h = 10, this.colours = 4, bool solvable = true, Random? random})
      : rng = random ?? Random() {
    grid = solvable ? _generateSolvable() : [for (var i = 0; i < w * h; i++) rng.nextInt(colours) + 1];
  }

  final int w, h, colours;
  final Random rng;

  /// Row-major, row 0 at the top; 0 = empty.
  late List<int> grid;
  int score = 0;
  final List<(List<int>, int)> _history = [];

  List<int> snapshot() => [score, ...grid];

  bool restore(List<int> data) {
    if (data.length != w * h + 1 || data.first < 0 ||
        data.skip(1).any((v) => v < 0 || v > colours)) return false;
    grid = data.skip(1).toList();
    score = data.first;
    _history.clear();
    return true;
  }

  int at(int x, int y) => (x < 0 || x >= w || y < 0 || y >= h) ? 0 : grid[y * w + x];

  List<int> group(int i) {
    final c = grid[i];
    if (c == 0) return [];
    final seen = {i};
    final stack = [i];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final x = p % w, y = p ~/ w;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (at(nx, ny) == c && seen.add(ny * w + nx)) stack.add(ny * w + nx);
      }
    }
    return seen.toList();
  }

  static int points(int n) => n < 2 ? 0 : (n - 2) * (n - 2);

  bool remove(int i) {
    final g = group(i);
    if (g.length < 2) return false;
    _history.add((List.of(grid), score));
    for (final p in g) {
      grid[p] = 0;
    }
    score += points(g.length);
    _settle(grid);
    if (cleared) score += 1000;
    return true;
  }

  void _settle(List<int> g) {
    // Gravity.
    for (var x = 0; x < w; x++) {
      final col = [for (var y = h - 1; y >= 0; y--) if (g[y * w + x] != 0) g[y * w + x]];
      for (var y = h - 1, k = 0; y >= 0; y--, k++) {
        g[y * w + x] = k < col.length ? col[k] : 0;
      }
    }
    // Close empty columns to the left.
    var dst = 0;
    for (var x = 0; x < w; x++) {
      if (g[(h - 1) * w + x] == 0) continue;
      if (dst != x) {
        for (var y = 0; y < h; y++) {
          g[y * w + dst] = g[y * w + x];
          g[y * w + x] = 0;
        }
      }
      dst++;
    }
  }

  bool get cleared => grid.every((c) => c == 0);
  bool get stuck => !cleared && ![for (var i = 0; i < grid.length; i++) i].any((i) => grid[i] != 0 && group(i).length >= 2);
  int get remaining => grid.where((c) => c != 0).length;
  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    grid = h.$1;
    score = h.$2;
  }

  /// Builds a board by inserting vertical two-cell blobs (or new two-cell
  /// columns) whose colour differs from every neighbour, so removing the
  /// blobs in reverse order clears the board.
  List<int> _generateSolvable() {
    for (var attempt = 0; attempt < 200; attempt++) {
      final cols = <List<int>>[]; // bottom-up stacks
      final first = (w * h).isOdd ? 3 : 2;
      cols.add(List.filled(first, rng.nextInt(colours) + 1));
      var filled = first;
      var failures = 0;
      while (filled < w * h && failures < 400) {
        // Insertion: (column index, height index) or new column at index.
        final options = <(int, int, bool)>[];
        for (var c = 0; c < cols.length; c++) {
          if (cols[c].length + 2 > h) continue;
          for (var y = 0; y <= cols[c].length; y++) {
            options.add((c, y, false));
          }
        }
        if (cols.length < w) {
          for (var c = 0; c <= cols.length; c++) {
            options.add((c, 0, true));
          }
        }
        if (options.isEmpty) break;
        final (c, y, newCol) = options[rng.nextInt(options.length)];
        final trial = [for (final s in cols) List.of(s)];
        if (newCol) {
          trial.insert(c, [0, 0]);
        } else {
          trial[c].insertAll(y, [0, 0]);
        }
        int cell(int cx, int cy) => cx < 0 || cx >= trial.length || cy < 0 || cy >= trial[cx].length ? -1 : trial[cx][cy];
        final neighbours = <int>{
          cell(c - 1, y), cell(c - 1, y + 1), cell(c + 1, y), cell(c + 1, y + 1),
          cell(c, y - 1), cell(c, y + 2),
        };
        final allowed = [for (var k = 1; k <= colours; k++) if (!neighbours.contains(k)) k];
        if (allowed.isEmpty) {
          failures++;
          continue;
        }
        final colour = allowed[rng.nextInt(allowed.length)];
        trial[c][y] = colour;
        trial[c][y + 1] = colour;
        cols
          ..clear()
          ..addAll(trial);
        filled += 2;
      }
      if (filled != w * h) continue;
      final g = List.filled(w * h, 0);
      for (var x = 0; x < cols.length; x++) {
        for (var k = 0; k < cols[x].length; k++) {
          g[(h - 1 - k) * w + x] = cols[x][k];
        }
      }
      return g;
    }
    return [for (var i = 0; i < w * h; i++) rng.nextInt(colours) + 1];
  }
}
