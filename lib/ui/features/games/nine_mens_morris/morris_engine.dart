import 'dart:math';

/// Nine Men's Morris on the standard 24-point board.
///
/// Points are numbered row by row:
///  0-----------1-----------2
///  |   3-------4-------5   |
///  |   |   6---7---8   |   |
///  9--10--11       12-13--14
///  |   |  15--16--17   |   |
///  |  18------19------20   |
/// 21----------22----------23
const List<List<int>> morrisAdjacent = [
  [1, 9], [0, 2, 4], [1, 14], [4, 10], [1, 3, 5, 7], [4, 13], [7, 11], [4, 6, 8], [7, 12],
  [0, 10, 21], [3, 9, 11, 18], [6, 10, 15], [8, 13, 17], [5, 12, 14, 20], [2, 13, 23],
  [11, 16], [15, 17, 19], [12, 16], [10, 19], [16, 18, 20, 22], [13, 19], [9, 22],
  [19, 21, 23], [14, 22],
];

const List<List<int>> morrisMills = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11], [12, 13, 14], [15, 16, 17], [18, 19, 20],
  [21, 22, 23], [0, 9, 21], [3, 10, 18], [6, 11, 15], [1, 4, 7], [16, 19, 22], [8, 12, 17],
  [5, 13, 20], [2, 14, 23],
];

/// Grid position (0-6, 0-6) of each point, for drawing.
const List<(int, int)> morrisCoords = [
  (0, 0), (3, 0), (6, 0), (1, 1), (3, 1), (5, 1), (2, 2), (3, 2), (4, 2),
  (0, 3), (1, 3), (2, 3), (4, 3), (5, 3), (6, 3), (2, 4), (3, 4), (4, 4),
  (1, 5), (3, 5), (5, 5), (0, 6), (3, 6), (6, 6),
];

/// A move: place (from == null) or slide/fly, plus an optional removal.
class MorrisMove {
  const MorrisMove(this.to, {this.from, this.remove});
  final int? from;
  final int to;
  final int? remove;
}

class MorrisState {
  MorrisState()
      : board = List.filled(24, 0),
        inHand = [9, 9],
        turn = 1;
  MorrisState._(this.board, this.inHand, this.turn, this.quietMoves);

  /// 0 empty, 1 white, 2 black.
  final List<int> board;
  final List<int> inHand;
  int turn;
  int quietMoves = 0;

  MorrisState copy() => MorrisState._(List.of(board), List.of(inHand), turn, quietMoves);

  int onBoard(int p) => board.where((v) => v == p).length;
  int total(int p) => onBoard(p) + inHand[p - 1];
  bool placing(int p) => inHand[p - 1] > 0;
  bool flying(int p) => !placing(p) && onBoard(p) == 3;

  bool inMill(int point, [List<int>? b]) {
    final bd = b ?? board;
    final p = bd[point];
    if (p == 0) return false;
    return morrisMills.any((m) => m.contains(point) && m.every((i) => bd[i] == p));
  }

  /// Opponent pieces that may be removed: those not in mills, unless all are.
  List<int> removable(int byPlayer) {
    final opp = 3 - byPlayer;
    final theirs = [for (var i = 0; i < 24; i++) if (board[i] == opp) i];
    final free = theirs.where((i) => !inMill(i)).toList();
    return free.isNotEmpty ? free : theirs;
  }

  /// Placements/slides for the side to move, without removal choice.
  List<(int?, int)> steps() {
    final p = turn;
    final res = <(int?, int)>[];
    if (placing(p)) {
      for (var i = 0; i < 24; i++) {
        if (board[i] == 0) res.add((null, i));
      }
      return res;
    }
    for (var i = 0; i < 24; i++) {
      if (board[i] != p) continue;
      final targets = flying(p) ? [for (var j = 0; j < 24; j++) if (board[j] == 0) j] : morrisAdjacent[i].where((j) => board[j] == 0);
      for (final j in targets) {
        res.add((i, j));
      }
    }
    return res;
  }

  bool formsMill(int? from, int to) {
    final b = List.of(board);
    if (from != null) b[from] = 0;
    b[to] = turn;
    return inMill(to, b);
  }

  List<MorrisMove> legalMoves() {
    final res = <MorrisMove>[];
    for (final (from, to) in steps()) {
      if (formsMill(from, to)) {
        final after = copy();
        if (from != null) after.board[from] = 0;
        after.board[to] = turn;
        for (final r in after.removable(turn)) {
          res.add(MorrisMove(to, from: from, remove: r));
        }
      } else {
        res.add(MorrisMove(to, from: from));
      }
    }
    return res;
  }

  void apply(MorrisMove m) {
    if (m.from == null) {
      inHand[turn - 1]--;
    } else {
      board[m.from!] = 0;
    }
    board[m.to] = turn;
    if (m.remove != null) {
      board[m.remove!] = 0;
      quietMoves = 0;
    } else {
      quietMoves++;
    }
    turn = 3 - turn;
  }

  /// Winner (1/2), 3 for a draw, or 0 while the game continues.
  int get result {
    for (final p in [1, 2]) {
      if (total(p) < 3) return 3 - p;
    }
    if (steps().isEmpty) return 3 - turn;
    if (quietMoves >= 100) return 3;
    return 0;
  }

  int evaluate(int me) {
    final opp = 3 - me;
    final r = result;
    if (r == me) return 100000;
    if (r == opp) return -100000;
    var s = (total(me) - total(opp)) * 100;
    for (final m in morrisMills) {
      final mine = m.where((i) => board[i] == me).length;
      final theirs = m.where((i) => board[i] == opp).length;
      if (theirs == 0 && mine == 2) s += 12;
      if (mine == 0 && theirs == 2) s -= 12;
      if (mine == 3) s += 8;
      if (theirs == 3) s -= 8;
    }
    // Mobility in the moving phase.
    if (!placing(me) && !placing(opp)) {
      final save = turn;
      turn = me;
      final a = steps().length;
      turn = opp;
      final b = steps().length;
      turn = save;
      s += (a - b) * 3;
    }
    return s;
  }
}

int _search(MorrisState s, int depth, int alpha, int beta, int me) {
  if (depth == 0 || s.result != 0) return s.evaluate(me);
  final moves = s.legalMoves();
  final maximize = s.turn == me;
  var best = maximize ? -1 << 30 : 1 << 30;
  for (final m in moves) {
    final c = s.copy()..apply(m);
    final v = _search(c, depth - 1, alpha, beta, me);
    if (maximize) {
      best = max(best, v);
      alpha = max(alpha, v);
    } else {
      best = min(best, v);
      beta = min(beta, v);
    }
    if (beta <= alpha) break;
  }
  return best;
}

MorrisMove morrisAi(MorrisState s, int level, Random rng) {
  final moves = s.legalMoves()..shuffle(rng);
  if (level == 0 && rng.nextDouble() < .5) return moves.first;
  final placingPhase = s.placing(1) || s.placing(2);
  final depth = level == 2 ? (placingPhase ? 3 : 4) : level == 1 ? 2 : 1;
  MorrisMove? best;
  var bestV = -1 << 30;
  for (final m in moves) {
    final c = s.copy()..apply(m);
    final v = _search(c, depth - 1, -1 << 30, 1 << 30, s.turn);
    if (v > bestV) {
      bestV = v;
      best = m;
    }
  }
  return best!;
}
