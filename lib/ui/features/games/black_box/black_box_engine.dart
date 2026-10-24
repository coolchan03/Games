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

  /// A box with balls at exactly [cells] (used to compare arrangements and
  /// to resume a saved game).
  BlackBoxGame.fixed(this.n, Set<int> cells)
      : balls = cells.length,
        rng = Random() {
    hidden = cells;
  }

  final int n, balls;
  final Random rng;
  late final Set<int> hidden;
  final Set<int> guesses = {};
  final Map<int, LaserResult> fired = {};
  bool revealed = false;

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

  /// Snapshot for saving: hidden balls, marks, fired ports, revealed flag.
  List<int> get snapshot {
    final ports = [for (final e in fired.entries) e.key];
    return [
      revealed ? 1 : 0,
      hidden.length, ...hidden,
      guesses.length, ...guesses,
      ports.length, ...ports,
    ];
  }

  /// Rebuilds a game from [snapshot]; null if the data does not fit an
  /// [n]×[n] box with [balls] balls.
  static BlackBoxGame? fromSnapshot(int n, int balls, List<int> data) {
    try {
      var i = 0;
      List<int> take() {
        final count = data[++i];
        final out = data.sublist(i + 1, i + 1 + count);
        i += count;
        return out;
      }

      final revealed = data[0] == 1;
      final hidden = take();
      final guesses = take();
      final ports = take();
      if (hidden.length != balls ||
          [...hidden, ...guesses].any((c) => c < 0 || c >= n * n) ||
          guesses.length > balls ||
          ports.any((p) => p < 0 || p >= 4 * n)) {
        return null;
      }
      final game = BlackBoxGame.fixed(n, hidden.toSet());
      game.guesses.addAll(guesses);
      for (final p in ports) {
        game.fire(p);
      }
      game.revealed = revealed;
      return game;
    } catch (_) {
      return null;
    }
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
  int get score => lasersUsed + (correct ? 0 : wrong * 5);

  /// As in Tatham's blackbox.c, a guess is right when it has the right
  /// number of balls and no laser could tell it apart from the real box.
  bool get correct =>
      guesses.length == balls && (wrong == 0 || indistinguishable(guesses));

  /// Whether balls at [cells] give the same result for every port.
  bool indistinguishable(Set<int> cells) {
    final other = BlackBoxGame.fixed(n, Set.of(cells));
    for (var p = 0; p < 4 * n; p++) {
      final a = trace(p), b = other.trace(p);
      if (a.kind != b.kind || a.exit != b.exit) return false;
    }
    return true;
  }
}

/// The 20 numbered Black Box levels as (box size, hidden balls). Each
/// attempt hides the balls afresh, so retrying a level is a new puzzle.
class BlackBoxLevels {
  static const specs = [
    (5, 2), (5, 3), (6, 2), (6, 3), (6, 4),
    (7, 3), (7, 4), (7, 5), (8, 3), (8, 4),
    (8, 5), (8, 6), (9, 4), (9, 5), (9, 6),
    (9, 7), (10, 5), (10, 6), (10, 7), (10, 8),
  ];

  static BlackBoxGame build(int level, {Random? random}) {
    final (n, balls) = specs[level - 1];
    return BlackBoxGame(n: n, balls: balls, random: random);
  }
}
