import 'dart:math';

/// Hex on an n×n rhombus. Red (1) connects top and bottom, Blue (2)
/// connects left and right. There are no draws.
class HexGame {
  HexGame({this.n = 9}) : cells = List.filled(n * n, 0);

  final int n;
  final List<int> cells;
  int turn = 1;
  int winner = 0;
  final List<int> history = [];

  static const _nb = [(0, -1), (1, -1), (1, 0), (0, 1), (-1, 1), (-1, 0)];

  Iterable<int> neighbours(int i) sync* {
    final x = i % n, y = i ~/ n;
    for (final (dx, dy) in _nb) {
      final nx = x + dx, ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < n && ny < n) yield ny * n + nx;
    }
  }

  /// Does [p] connect its two sides on [board]?
  bool connected(List<int> board, int p) {
    final stack = <int>[];
    final seen = List.filled(n * n, false);
    for (var k = 0; k < n; k++) {
      final start = p == 1 ? k : k * n;
      if (board[start] == p) {
        stack.add(start);
        seen[start] = true;
      }
    }
    while (stack.isNotEmpty) {
      final c = stack.removeLast();
      if (p == 1 ? c ~/ n == n - 1 : c % n == n - 1) return true;
      for (final m in neighbours(c)) {
        if (!seen[m] && board[m] == p) {
          seen[m] = true;
          stack.add(m);
        }
      }
    }
    return false;
  }

  /// Winning path cells for display.
  Set<int> winningPath() {
    if (winner == 0) return {};
    final p = winner;
    final prev = <int, int>{};
    final queue = <int>[];
    for (var k = 0; k < n; k++) {
      final s = p == 1 ? k : k * n;
      if (cells[s] == p) {
        queue.add(s);
        prev[s] = -1;
      }
    }
    var head = 0;
    while (head < queue.length) {
      final c = queue[head++];
      if (p == 1 ? c ~/ n == n - 1 : c % n == n - 1) {
        final path = <int>{};
        for (var x = c; x != -1; x = prev[x]!) {
          path.add(x);
        }
        return path;
      }
      for (final m in neighbours(c)) {
        if (cells[m] == p && !prev.containsKey(m)) {
          prev[m] = c;
          queue.add(m);
        }
      }
    }
    return {};
  }

  bool play(int i) {
    if (winner != 0 || cells[i] != 0) return false;
    cells[i] = turn;
    history.add(i);
    if (connected(cells, turn)) winner = turn;
    turn = 3 - turn;
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final i = history.removeLast();
    turn = cells[i];
    cells[i] = 0;
    winner = 0;
  }

  /// Monte Carlo move choice with all-moves-as-first statistics: random
  /// fills of the board are scored, and each empty cell is credited with the
  /// result when the computer owned it.
  int aiMove(int playouts, Random rng) {
    final me = turn;
    final empty = [for (var i = 0; i < n * n; i++) if (cells[i] == 0) i];
    if (history.isEmpty) return (n ~/ 2) * n + n ~/ 2;
    // Immediate win or block.
    for (final p in [me, 3 - me]) {
      for (final e in empty) {
        cells[e] = p;
        final win = connected(cells, p);
        cells[e] = 0;
        if (win) return e;
      }
    }
    final wins = List.filled(n * n, 0.0), plays = List.filled(n * n, 0.0);
    final board = List.of(cells);
    final pool = List.of(empty);
    final myCount = (empty.length + 1) ~/ 2;
    for (var k = 0; k < playouts; k++) {
      pool.shuffle(rng);
      for (var j = 0; j < pool.length; j++) {
        board[pool[j]] = j < myCount ? me : 3 - me;
      }
      final won = connected(board, me);
      for (var j = 0; j < myCount; j++) {
        plays[pool[j]]++;
        if (won) wins[pool[j]]++;
      }
    }
    var best = empty.first, bestRate = -1.0;
    for (final e in empty) {
      final rate = plays[e] == 0 ? 0.0 : wins[e] / plays[e];
      if (rate > bestRate) {
        bestRate = rate;
        best = e;
      }
    }
    return best;
  }
}
