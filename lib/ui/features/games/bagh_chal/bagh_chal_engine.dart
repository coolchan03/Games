import 'dart:math';

import '../common/alquerque_board.dart';

/// Bagh Chal (Nepalese "tiger moves"): 4 tigers against 20 goats on the
/// Alquerque board. Goats are placed one per turn, then move. Tigers move
/// one step or jump a goat to capture it. Tigers win by capturing five
/// goats; goats win by leaving no tiger a legal move.
class BaghMove {
  const BaghMove(this.to, {this.from, this.capture});
  final int? from;
  final int to;
  final int? capture;
}

class BaghState {
  BaghState()
      : cells = List.filled(25, 0)
          ..[0] = 2
          ..[4] = 2
          ..[20] = 2
          ..[24] = 2;
  BaghState._(this.cells, this.goatsToPlace, this.captured, this.turn, this.quiet);

  /// 0 empty, 1 goat, 2 tiger.
  final List<int> cells;
  int goatsToPlace = 20;
  int captured = 0;
  int turn = 1; // goats move first
  int quiet = 0;

  BaghState copy() => BaghState._(List.of(cells), goatsToPlace, captured, turn, quiet);

  List<BaghMove> moves() {
    final res = <BaghMove>[];
    if (turn == 1) {
      if (goatsToPlace > 0) {
        for (var i = 0; i < 25; i++) {
          if (cells[i] == 0) res.add(BaghMove(i));
        }
        return res;
      }
      for (var i = 0; i < 25; i++) {
        if (cells[i] != 1) continue;
        for (final (dx, dy) in AlquerqueGeometry.dirs(i)) {
          final t = AlquerqueGeometry.step(i, dx, dy);
          if (t != null && cells[t] == 0) res.add(BaghMove(t, from: i));
        }
      }
      return res;
    }
    for (var i = 0; i < 25; i++) {
      if (cells[i] != 2) continue;
      for (final (dx, dy) in AlquerqueGeometry.dirs(i)) {
        final t = AlquerqueGeometry.step(i, dx, dy);
        if (t == null) continue;
        if (cells[t] == 0) {
          res.add(BaghMove(t, from: i));
        } else if (cells[t] == 1) {
          final j = AlquerqueGeometry.step(i, dx, dy, 2);
          if (j != null && cells[j] == 0) res.add(BaghMove(j, from: i, capture: t));
        }
      }
    }
    return res;
  }

  void apply(BaghMove m) {
    if (m.from == null) {
      goatsToPlace--;
    } else {
      cells[m.from!] = 0;
    }
    cells[m.to] = turn;
    if (m.capture != null) {
      cells[m.capture!] = 0;
      captured++;
      quiet = 0;
    } else {
      quiet++;
    }
    turn = 3 - turn;
  }

  /// 1 goats win, 2 tigers win, 3 draw, 0 ongoing.
  int get result {
    if (captured >= 5) return 2;
    if (turn == 2 && moves().isEmpty) return 1;
    if (turn == 1 && moves().isEmpty) return 2;
    if (quiet >= 120) return 3;
    return 0;
  }

  int evaluate() {
    final r = result;
    if (r == 1) return 10000;
    if (r == 2) return -10000;
    // From the goats' point of view.
    final saved = turn;
    turn = 2;
    final tigerMoves = moves();
    turn = saved;
    final threats = tigerMoves.where((m) => m.capture != null).length;
    return -captured * 300 - tigerMoves.length * 8 - threats * 40;
  }
}

int _search(BaghState s, int depth, int alpha, int beta) {
  if (depth == 0 || s.result != 0) return s.evaluate();
  final moves = s.moves();
  if (s.turn == 1) {
    var best = -1 << 30;
    for (final m in moves) {
      final v = _search(s.copy()..apply(m), depth - 1, alpha, beta);
      best = max(best, v);
      alpha = max(alpha, v);
      if (alpha >= beta) break;
    }
    return best;
  }
  var best = 1 << 30;
  for (final m in moves) {
    final v = _search(s.copy()..apply(m), depth - 1, alpha, beta);
    best = min(best, v);
    beta = min(beta, v);
    if (alpha >= beta) break;
  }
  return best;
}

BaghMove baghAi(BaghState s, int level, Random rng) {
  final moves = s.moves()..shuffle(rng);
  if (level == 0 && rng.nextDouble() < .5) return moves.first;
  final depth = [1, 3, 4][level];
  BaghMove? best;
  var bestV = 0;
  for (final m in moves) {
    final v = _search(s.copy()..apply(m), depth - 1, -1 << 30, 1 << 30);
    if (best == null || (s.turn == 1 ? v > bestV : v < bestV)) {
      best = m;
      bestV = v;
    }
  }
  return best!;
}
