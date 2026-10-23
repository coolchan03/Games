// Rules of "Black Box" as implemented in Simon Tatham's Portable Puzzle
// Collection (blackbox.c, MIT licence): hidden balls deflect lasers.
import 'dart:math';

/// Result of firing a laser: hit, reflection, or the exit port it left by.
class LaserResult {
  const LaserResult.hit() : kind = 'H', exit = null;
  const LaserResult.reflect() : kind = 'R', exit = null;
  const LaserResult.exitAt(int this.exit) : kind = 'X';
  final String kind;
  final int? exit;
}

/// Ports are numbered clockwise: top 0..n-1 (left to right), right
/// n..2n-1 (top to bottom), bottom 2n..3n-1 (right to left), left
/// 3n..4n-1 (bottom to top).
class BlackBoxGame {
  BlackBoxGame({this.n = 8, this.balls = 5, Random? random}) : rng = random ?? Random() {
    final cells = List.generate(n * n, (i) => i)..shuffle(rng);
    hidden = cells.take(balls).toSet();
  }

  final int n, balls;
  final Random rng;
  late final Set<int> hidden;
  final Set<int> guesses = {};
  final Map<int, LaserResult> fired = {};
  bool revealed = false;

  /// Save the hidden board, marked guesses and fired ports as integer flags.
  /// Restoring through fire() recalculates all exit pairs from actual rules.
  List<int> snapshot() => [
    revealed ? 1 : 0,
    for (var i = 0; i < n * n; i++) hidden.contains(i) ? 1 : 0,
    for (var i = 0; i < n * n; i++) guesses.contains(i) ? 1 : 0,
    for (var i = 0; i < 4 * n; i++) fired.containsKey(i) ? 1 : 0,
  ];

  static BlackBoxGame? fromSnapshot({
    required int n, required int balls, required List<int> data,
  }) {
    if (n < 1 || balls < 1 || balls > n * n ||
        data.length != 1 + 2 * n * n + 4 * n ||
        data.any((v) => v != 0 && v != 1)) return null;
    final board = BlackBoxGame(n: n, balls: balls);
    final hiddenFlags = data.skip(1).take(n * n).toList();
    final guessesFlags = data.skip(1 + n * n).take(n * n).toList();
    final firedFlags = data.skip(1 + 2 * n * n).toList();
    if (hiddenFlags.where((v) => v == 1).length != balls ||
        guessesFlags.where((v) => v == 1).length > balls) return null;
    board.hidden
      ..clear()
      ..addAll([for (var i = 0; i < n * n; i++) if (hiddenFlags[i] == 1) i]);
    board.guesses.addAll([
      for (var i = 0; i < n * n; i++) if (guessesFlags[i] == 1) i,
    ]);
    for (var p = 0; p < 4 * n; p++) {
      if (firedFlags[p] == 1 && !board.fired.containsKey(p)) board.fire(p);
    }
    if (board.fired.length != firedFlags.where((flag) => flag == 1).length ||
        board.fired.keys.any((port) => firedFlags[port] != 1)) return null;
    if (data.first == 1 && board.guesses.length != balls) return null;
    board.revealed = data.first == 1;
    return board;
  }

  bool ball(int x, int y) => x >= 0 && y >= 0 && x < n && y < n && hidden.contains(y * n + x);

  /// Entry cell and direction for a port.
  (int, int, int, int) _entry(int port) {
    final side = port ~/ n, k = port % n;
    return switch (side) {
      0 => (k, 0, 0, 1),
      1 => (n - 1, k, -1, 0),
      2 => (n - 1 - k, n - 1, 0, -1),
      _ => (0, n - 1 - k, 1, 0),
    };
  }

  int _portFor(int x, int y, int dx, int dy) {
    // Leaving the grid from (x, y) moving (dx, dy).
    if (dy == -1) return x; // out the top
    if (dx == 1) return n + y; // out the right
    if (dy == 1) return 2 * n + (n - 1 - x); // out the bottom
    return 3 * n + (n - 1 - y); // out the left
  }

  bool _inside(int x, int y) => x >= 0 && y >= 0 && x < n && y < n;

  LaserResult trace(int port) {
    final (ex, ey, sdx, sdy) = _entry(port);
    var dx = sdx, dy = sdy;
    // Start just outside the box, in front of the entry square.
    var x = ex - dx, y = ey - dy;
    for (var steps = 0; steps < 8 * n * n; steps++) {
      final ax = x + dx, ay = y + dy;
      if (_inside(x, y) && !_inside(ax, ay)) {
        final out = _portFor(x, y, dx, dy);
        return out == port ? const LaserResult.reflect() : LaserResult.exitAt(out);
      }
      if (ball(ax, ay)) return const LaserResult.hit();
      final a = ball(ax - dy, ay + dx), b = ball(ax + dy, ay - dx);
      if (a && b) return const LaserResult.reflect();
      if (a || b) {
        // A ball diagonally ahead turns the laser away from it; at the edge
        // of the box that sends it straight back out.
        if (!_inside(x, y)) return const LaserResult.reflect();
        final (ndx, ndy) = a ? (dy, -dx) : (-dy, dx);
        dx = ndx;
        dy = ndy;
        continue;
      }
      x = ax;
      y = ay;
    }
    return const LaserResult.reflect();
  }

  void fire(int port) {
    if (revealed || fired.containsKey(port)) return;
    final r = trace(port);
    fired[port] = r;
    if (r.kind == 'X') fired[r.exit!] = LaserResult.exitAt(port);
  }

  void toggleGuess(int cell) {
    if (revealed) return;
    if (!guesses.remove(cell) && guesses.length < balls) guesses.add(cell);
  }

  int get lasersUsed {
    final seen = <int>{};
    var count = 0;
    fired.forEach((p, r) {
      if (seen.contains(p)) return;
      seen.add(p);
      if (r.kind == 'X') seen.add(r.exit!);
      count++;
    });
    return count;
  }

  int get wrong => guesses.difference(hidden).length;
  int get score => lasersUsed + wrong * 5;
  bool get correct => guesses.length == balls && wrong == 0;
}
