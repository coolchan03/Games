import 'dart:math';

/// Neutron (Robert A. Kraus, 1978) on a 5×5 board. Each player has five
/// pieces on their home row and the neutral Neutron starts in the centre.
/// A turn is: slide the Neutron, then slide one of your own pieces. Pieces
/// slide in any of eight directions as far as they can. Whoever's home row
/// the Neutron reaches wins, no matter who moved it there; a player who
/// cannot move the Neutron loses. The first player skips the Neutron on the
/// very first turn.
class NeutronMove {
  const NeutronMove(this.neutronTo, this.from, this.to);
  final int? neutronTo;
  final int from, to;
}

const _dirs = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)];

class NeutronState {
  NeutronState() : cells = List.filled(25, 0) {
    for (var x = 0; x < 5; x++) {
      cells[20 + x] = 1; // player 1 home row is the bottom
      cells[x] = 2;
    }
    cells[12] = 3;
  }
  NeutronState._(this.cells, this.turn, this.firstMove, this.plies);

  /// 0 empty, 1/2 players, 3 neutron.
  final List<int> cells;
  int turn = 1;
  bool firstMove = true;
  int plies = 0;

  NeutronState copy() => NeutronState._(List.of(cells), turn, firstMove, plies);

  int get neutron => cells.indexOf(3);

  List<int> slides(List<int> board, int from) {
    final res = <int>[];
    for (final (dx, dy) in _dirs) {
      var x = from % 5, y = from ~/ 5;
      var moved = false;
      while (true) {
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx > 4 || ny > 4 || board[ny * 5 + nx] != 0) break;
        x = nx;
        y = ny;
        moved = true;
      }
      if (moved) res.add(y * 5 + x);
    }
    return res;
  }

  List<NeutronMove> moves() {
    final res = <NeutronMove>[];
    final neutronOptions = firstMove ? <int?>[null] : slides(cells, neutron).cast<int?>();
    for (final nt in neutronOptions) {
      final board = List.of(cells);
      if (nt != null) {
        board[neutron] = 0;
        board[nt] = 3;
        // Moving the Neutron home ends the game at once.
        if (nt ~/ 5 == 4 || nt ~/ 5 == 0) {
          res.add(NeutronMove(nt, -1, -1));
          continue;
        }
      }
      for (var i = 0; i < 25; i++) {
        if (board[i] != turn) continue;
        for (final t in slides(board, i)) {
          res.add(NeutronMove(nt, i, t));
        }
      }
    }
    return res;
  }

  void apply(NeutronMove m) {
    if (m.neutronTo != null) {
      cells[neutron] = 0;
      cells[m.neutronTo!] = 3;
    }
    if (m.from >= 0) {
      cells[m.from] = 0;
      cells[m.to] = turn;
    }
    firstMove = false;
    plies++;
    turn = 3 - turn;
  }

  /// Winner (1/2), or 0 while play continues.
  int get result {
    final row = neutron ~/ 5;
    if (row == 4) return 1;
    if (row == 0) return 2;
    if (!firstMove && slides(cells, neutron).isEmpty) return 3 - turn;
    if (moves().isEmpty) return 3 - turn;
    return 0;
  }

  int evaluate(int me) {
    final r = result;
    if (r == me) return 10000;
    if (r != 0) return -10000;
    // Prefer the neutron near my home row and mobility.
    final row = neutron ~/ 5;
    final toward = me == 1 ? row : 4 - row;
    return toward * 30 + (turn == me ? 5 : -5);
  }
}

int _neu(NeutronState s, int depth, int alpha, int beta, int me) {
  if (depth == 0 || s.result != 0) return s.evaluate(me);
  final maximize = s.turn == me;
  var best = maximize ? -1 << 30 : 1 << 30;
  for (final m in s.moves()) {
    final v = _neu(s.copy()..apply(m), depth - 1, alpha, beta, me);
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

NeutronMove neutronAi(NeutronState s, int level, Random rng) {
  final moves = s.moves()..shuffle(rng);
  // Always take an immediate win.
  for (final m in moves) {
    final c = s.copy()..apply(m);
    if (c.result == s.turn) return m;
  }
  if (level == 0) {
    final safe = moves.where((m) {
      final c = s.copy()..apply(m);
      return !c.moves().any((r) => (c.copy()..apply(r)).result == c.turn);
    }).toList();
    return (safe.isNotEmpty ? safe : moves)[rng.nextInt(safe.isNotEmpty ? safe.length : moves.length)];
  }
  final depth = level == 1 ? 2 : 3;
  NeutronMove? best;
  var bestV = -1 << 30;
  for (final m in moves) {
    final v = _neu(s.copy()..apply(m), depth - 1, -1 << 30, 1 << 30, s.turn);
    if (v > bestV) {
      bestV = v;
      best = m;
    }
  }
  return best!;
}
