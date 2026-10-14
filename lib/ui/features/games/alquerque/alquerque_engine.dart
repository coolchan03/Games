import 'dart:math';

import '../common/alquerque_board.dart';

/// Alquerque (the ancestor of draughts). Each side has 12 pieces. Pieces
/// step along a line to an adjacent empty point — forwards or sideways,
/// never backwards. Capturing by jumping is compulsory and may continue
/// in a chain in any direction. Capture every enemy piece, or leave the
/// opponent without a move, to win.
class AlqMove {
  const AlqMove(this.path, this.captured);
  final List<int> path;
  final List<int> captured;
  int get from => path.first;
  int get to => path.last;
}

class AlquerqueState {
  AlquerqueState() : cells = List.filled(25, 0) {
    for (var i = 0; i < 25; i++) {
      final x = i % 5, y = i ~/ 5;
      if (y >= 3 || (y == 2 && x >= 3)) cells[i] = 1;
      if (y <= 1 || (y == 2 && x <= 1)) cells[i] = 2;
    }
  }
  AlquerqueState._(this.cells, this.turn, this.quiet);

  final List<int> cells;
  int turn = 1;
  int quiet = 0;

  AlquerqueState copy() => AlquerqueState._(List.of(cells), turn, quiet);

  /// Forward direction in y for each player.
  int forward(int p) => p == 1 ? -1 : 1;

  void _captures(int at, List<int> path, List<int> caps, List<AlqMove> out, List<int> board) {
    var extended = false;
    for (final (dx, dy) in AlquerqueGeometry.dirs(at)) {
      final over = AlquerqueGeometry.step(at, dx, dy);
      final land = AlquerqueGeometry.step(at, dx, dy, 2);
      if (over == null || land == null) continue;
      if (board[over] != 3 - turn || board[land] != 0 || caps.contains(over)) continue;
      extended = true;
      final saved = board[over];
      board[over] = 0;
      board[land] = turn;
      board[at] = 0;
      _captures(land, [...path, land], [...caps, over], out, board);
      board[land] = 0;
      board[at] = turn;
      board[over] = saved;
    }
    if (!extended && caps.isNotEmpty) out.add(AlqMove(path, caps));
  }

  List<AlqMove> moves() {
    final caps = <AlqMove>[];
    final board = List.of(cells);
    for (var i = 0; i < 25; i++) {
      if (cells[i] == turn) _captures(i, [i], [], caps, board);
    }
    if (caps.isNotEmpty) return caps;
    final res = <AlqMove>[];
    for (var i = 0; i < 25; i++) {
      if (cells[i] != turn) continue;
      for (final (dx, dy) in AlquerqueGeometry.dirs(i)) {
        if (dy == -forward(turn)) continue; // no backward steps
        final t = AlquerqueGeometry.step(i, dx, dy);
        if (t != null && cells[t] == 0) res.add(AlqMove([i, t], const []));
      }
    }
    return res;
  }

  void apply(AlqMove m) {
    cells[m.from] = 0;
    for (final c in m.captured) {
      cells[c] = 0;
    }
    cells[m.to] = turn;
    quiet = m.captured.isEmpty ? quiet + 1 : 0;
    turn = 3 - turn;
  }

  int count(int p) => cells.where((c) => c == p).length;

  /// Winner, 3 for a draw, 0 ongoing.
  int get result {
    if (count(1) == 0) return 2;
    if (count(2) == 0) return 1;
    if (moves().isEmpty) return 3 - turn;
    if (quiet >= 60) return 3;
    return 0;
  }

  int evaluate(int me) {
    final r = result;
    if (r == me) return 10000;
    if (r == 3 - me) return -10000;
    var s = (count(me) - count(3 - me)) * 100;
    // Advancement.
    for (var i = 0; i < 25; i++) {
      if (cells[i] == 0) continue;
      final y = i ~/ 5;
      final adv = cells[i] == 1 ? 4 - y : y;
      s += cells[i] == me ? adv * 3 : -adv * 3;
    }
    return s;
  }
}

int _alq(AlquerqueState s, int depth, int alpha, int beta, int me) {
  if (depth == 0 || s.result != 0) return s.evaluate(me);
  final moves = s.moves();
  final maximize = s.turn == me;
  var best = maximize ? -1 << 30 : 1 << 30;
  for (final m in moves) {
    final v = _alq(s.copy()..apply(m), depth - 1, alpha, beta, me);
    if (maximize) {
      best = max(best, v);
      alpha = max(alpha, v);
    } else {
      best = min(best, v);
      beta = min(beta, v);
    }
    if (alpha >= beta) break;
  }
  return best;
}

AlqMove alquerqueAi(AlquerqueState s, int level, Random rng) {
  final moves = s.moves()..shuffle(rng);
  if (level == 0 && rng.nextDouble() < .4) return moves.first;
  final depth = [1, 3, 4][level];
  AlqMove? best;
  var bestV = -1 << 30;
  for (final m in moves) {
    final v = _alq(s.copy()..apply(m), depth - 1, -1 << 30, 1 << 30, s.turn);
    if (v > bestV) {
      bestV = v;
      best = m;
    }
  }
  return best!;
}
