import 'dart:math';

/// Freestyle Gomoku: five or more in a row wins.
class GomokuGame {
  GomokuGame({this.size = 15}) : board = List.filled(size * size, 0);

  final int size;
  final List<int> board;
  int turn = 1;
  int winner = 0;
  List<int> winLine = [];
  final List<int> history = [];

  bool get full => !board.contains(0);
  bool get over => winner != 0 || full;

  int at(int r, int c) => (r < 0 || c < 0 || r >= size || c >= size) ? -1 : board[r * size + c];

  static const dirs = [(0, 1), (1, 0), (1, 1), (1, -1)];

  bool play(int i) {
    if (over || board[i] != 0) return false;
    board[i] = turn;
    history.add(i);
    final line = _line(i);
    if (line != null) {
      winner = turn;
      winLine = line;
    }
    turn = 3 - turn;
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final i = history.removeLast();
    turn = board[i];
    board[i] = 0;
    winner = 0;
    winLine = [];
  }

  List<int>? _line(int i) {
    final p = board[i], r = i ~/ size, c = i % size;
    for (final (dr, dc) in dirs) {
      final cells = [i];
      for (final sgn in [1, -1]) {
        var k = 1;
        while (at(r + dr * k * sgn, c + dc * k * sgn) == p) {
          cells.add((r + dr * k * sgn) * size + c + dc * k * sgn);
          k++;
        }
      }
      if (cells.length >= 5) return cells;
    }
    return null;
  }

  /// Pattern score for [p] if a stone were at [i].
  int _score(int i, int p) {
    final r = i ~/ size, c = i % size;
    var total = 0;
    for (final (dr, dc) in dirs) {
      var count = 1, open = 0;
      for (final sgn in [1, -1]) {
        var k = 1;
        while (at(r + dr * k * sgn, c + dc * k * sgn) == p) {
          count++;
          k++;
        }
        if (at(r + dr * k * sgn, c + dc * k * sgn) == 0) open++;
      }
      if (count >= 5) {
        total += 1000000;
      } else if (count == 4) {
        total += open == 2 ? 100000 : open == 1 ? 12000 : 0;
      } else if (count == 3) {
        total += open == 2 ? 6000 : open == 1 ? 600 : 0;
      } else if (count == 2) {
        total += open == 2 ? 300 : open == 1 ? 40 : 0;
      } else {
        total += open * 4;
      }
    }
    return total;
  }

  int aiMove(int level, Random rng) {
    if (history.isEmpty) return (size ~/ 2) * size + size ~/ 2;
    final me = turn, opp = 3 - turn;
    var best = -1, bestScore = -1.0;
    for (var i = 0; i < board.length; i++) {
      if (board[i] != 0) continue;
      final r = i ~/ size, c = i % size;
      var near = false;
      for (var dr = -2; dr <= 2 && !near; dr++) {
        for (var dc = -2; dc <= 2 && !near; dc++) {
          if (at(r + dr, c + dc) > 0) near = true;
        }
      }
      if (!near) continue;
      final attack = _score(i, me).toDouble();
      final defend = _score(i, opp).toDouble();
      var s = attack * 1.1 + defend * [0.35, 0.9, 1.0][level];
      s *= 1 + rng.nextDouble() * [0.8, 0.1, 0.02][level];
      if (s > bestScore) {
        bestScore = s;
        best = i;
      }
    }
    return best;
  }
}
