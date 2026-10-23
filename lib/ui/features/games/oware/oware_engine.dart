import 'dart:math';

/// Oware Abapa. Pits 0–5 belong to South (player 0), 6–11 to North
/// (player 1); sowing is counter-clockwise. A sowing that started with 12+
/// seeds skips the pit it came from. If the last seed makes 2 or 3 in an
/// opponent's pit, those seeds are captured, together with preceding
/// opponent pits holding 2 or 3. A move that would capture all of the
/// opponent's seeds captures nothing ("grand slam"). You must leave the
/// opponent seeds to play when you can. The first to 25 wins.
class OwareState {
  OwareState()
      : pits = List.filled(12, 4),
        stores = [0, 0];
  OwareState._(this.pits, this.stores, this.turn, this.plies);

  final List<int> pits;
  final List<int> stores;
  int turn = 0;
  int plies = 0;

  OwareState copy() =>
      OwareState._(List.of(pits), List.of(stores), turn, plies);

  bool own(int pit, int p) => p == 0 ? pit < 6 : pit >= 6;
  int seedsOf(int p) => [
        for (var i = 0; i < 12; i++)
          if (own(i, p)) pits[i]
      ].fold(0, (a, b) => a + b);

  /// Result of sowing from [pit] without mutating this state.
  OwareState _sow(int pit) {
    final s = copy();
    var seeds = s.pits[pit];
    s.pits[pit] = 0;
    var i = pit;
    while (seeds > 0) {
      i = (i + 1) % 12;
      if (i == pit) continue;
      s.pits[i]++;
      seeds--;
    }
    // Captures, walking backwards through the opponent's pits.
    final opp = 1 - turn;
    var j = i;
    final captured = <int>[];
    while (own(j, opp) && (s.pits[j] == 2 || s.pits[j] == 3)) {
      captured.add(j);
      j = (j - 1 + 12) % 12;
    }
    final total = captured.fold(0, (a, c) => a + s.pits[c]);
    if (captured.isNotEmpty && total < s.seedsOf(opp)) {
      for (final c in captured) {
        s.pits[c] = 0;
      }
      s.stores[turn] += total;
    }
    s.turn = opp;
    s.plies++;
    return s;
  }

  List<int> legalMoves() {
    final mine = [
      for (var i = 0; i < 12; i++)
        if (own(i, turn) && pits[i] > 0) i
    ];
    // Must feed an opponent with no seeds if possible.
    if (seedsOf(1 - turn) == 0) {
      final feeding = mine.where((m) => _sow(m).seedsOf(1 - turn) > 0).toList();
      if (feeding.isNotEmpty) return feeding;
      return [];
    }
    return mine;
  }

  void play(int pit) {
    final s = _sow(pit);
    pits.setAll(0, s.pits);
    stores
      ..[0] = s.stores[0]
      ..[1] = s.stores[1];
    turn = s.turn;
    plies = s.plies;
  }

  /// Ends the game when no legal move remains: the remaining seeds go to
  /// the player on whose side they are. Returns winner (0/1), 2 for a draw,
  /// or -1 while play continues.
  int get result {
    if (stores[0] > 24) return 0;
    if (stores[1] > 24) return 1;
    if (stores[0] == 24 && stores[1] == 24) return 2;
    if (legalMoves().isEmpty || plies > 400) {
      final a = stores[0] + seedsOf(0), b = stores[1] + seedsOf(1);
      return a > b
          ? 0
          : b > a
              ? 1
              : 2;
    }
    return -1;
  }

  int evaluate(int me) {
    final r = result;
    if (r == me) return 10000;
    if (r == 1 - me) return -10000;
    if (r == 2) return 0;
    return (stores[me] - stores[1 - me]) * 10 + (seedsOf(me) - seedsOf(1 - me));
  }
}

int _ow(OwareState s, int depth, int alpha, int beta, int me) {
  if (depth == 0 || s.result != -1) return s.evaluate(me);
  final maximize = s.turn == me;
  var best = maximize ? -1 << 30 : 1 << 30;
  for (final m in s.legalMoves()) {
    final v = _ow(s._sow(m), depth - 1, alpha, beta, me);
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

int owareAi(OwareState s, int level, Random rng) {
  final moves = s.legalMoves()..shuffle(rng);
  if (level == 0 && rng.nextDouble() < .5) return moves.first;
  final depth = [2, 4, 6][level];
  var best = moves.first, bestV = -1 << 30;
  for (final m in moves) {
    final v = _ow(s._sow(m), depth - 1, -1 << 30, 1 << 30, s.turn);
    if (v > bestV) {
      bestV = v;
      best = m;
    }
  }
  return best;
}
