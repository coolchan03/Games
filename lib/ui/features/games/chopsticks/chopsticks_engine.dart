import 'dart:math';

/// Chopsticks (finger game). Each player has two hands showing 0-4 fingers.
/// On your turn you either ATTACK (tap one of your live hands against a live
/// enemy hand, adding your fingers to theirs) or SPLIT (re-deal your own
/// fingers between your two hands). A hand reaching 5 or more is out (or, in
/// the rollover variant, wraps around modulo 5). Lose both hands and you lose.
///
/// The game is tiny (about 450 positions), so [ChopsticksSolver] solves it
/// exactly by retrograde analysis: the computer can play perfectly and the
/// app can tell the player whether their position is winning, losing or
/// drawn with best play.

class ChopsticksMove {
  const ChopsticksMove.attack(this.from, this.to) : split = null;
  const ChopsticksMove.split(int low, int high)
      : from = -1,
        to = -1,
        split = low * 10 + high;

  /// Attack: own hand index (0/1) and enemy hand index (0/1).
  final int from, to;

  /// Split: encoded (low*10 + high) new hand values, else null.
  final int? split;

  bool get isSplit => split != null;
  int get splitLow => split! ~/ 10;
  int get splitHigh => split! % 10;

  @override
  bool operator ==(Object other) =>
      other is ChopsticksMove &&
      other.from == from &&
      other.to == to &&
      other.split == split;

  @override
  int get hashCode => Object.hash(from, to, split);

  @override
  String toString() => isSplit ? 'split $splitLow/$splitHigh' : 'attack $from->$to';
}

class ChopsticksState {
  /// hands[p] = [left, right] for player p (0 = bottom/human, 1 = top).
  ChopsticksState(List<int> p0, List<int> p1, this.turn, {this.rollover = false})
      : hands = [List.of(p0), List.of(p1)];

  factory ChopsticksState.start({bool rollover = false}) =>
      ChopsticksState([1, 1], [1, 1], 0, rollover: rollover);

  final List<List<int>> hands;
  final int turn;
  final bool rollover;

  bool isOut(int player) => hands[player][0] == 0 && hands[player][1] == 0;
  bool get over => isOut(0) || isOut(1);

  /// The winner once [over], else null.
  int? get winner => !over ? null : (isOut(0) ? 1 : 0);

  int total(int player) => hands[player][0] + hands[player][1];

  /// Canonical key: hand order does not matter for the maths.
  String get key {
    List<int> s(int p) => [...hands[p]]..sort();
    return '${s(0).join()}${s(1).join()}$turn${rollover ? 'r' : 'c'}';
  }

  List<ChopsticksMove> legalMoves() {
    if (over) return const [];
    final me = hands[turn], foe = hands[1 - turn];
    final moves = <ChopsticksMove>[];
    for (var f = 0; f < 2; f++) {
      if (me[f] == 0) continue;
      for (var t = 0; t < 2; t++) {
        if (foe[t] == 0) continue;
        // Identical enemy hands give identical results: offer one.
        if (t == 1 && foe[0] == foe[1]) continue;
        // Likewise for identical own hands.
        if (f == 1 && me[0] == me[1]) continue;
        moves.add(ChopsticksMove.attack(f, t));
      }
    }
    final sum = me[0] + me[1];
    final current = ([...me]..sort());
    for (var low = 0; low <= sum ~/ 2; low++) {
      final high = sum - low;
      if (high > 4) continue;
      if (low == current[0] && high == current[1]) continue;
      moves.add(ChopsticksMove.split(low, high));
    }
    return moves;
  }

  ChopsticksState apply(ChopsticksMove move) {
    final next = [List.of(hands[0]), List.of(hands[1])];
    if (move.isSplit) {
      // Keep the hand that already shows the larger count on the larger side
      // so the picture changes minimally.
      final me = next[turn];
      final bigFirst = me[0] >= me[1];
      me[0] = bigFirst ? move.splitHigh : move.splitLow;
      me[1] = bigFirst ? move.splitLow : move.splitHigh;
    } else {
      final sum = next[turn][move.from] + next[1 - turn][move.to];
      next[1 - turn][move.to] = rollover ? sum % 5 : (sum >= 5 ? 0 : sum);
    }
    return ChopsticksState(next[0], next[1], 1 - turn, rollover: rollover);
  }
}

/// Exact solution of the whole game for one rule set.
class ChopsticksSolver {
  ChopsticksSolver._(this.rollover) {
    _solve();
  }

  static final _cache = <bool, ChopsticksSolver>{};
  factory ChopsticksSolver(bool rollover) =>
      _cache.putIfAbsent(rollover, () => ChopsticksSolver._(rollover));

  final bool rollover;

  /// Plies until the player to move wins / loses with best play (a terminal
  /// loss is 0 plies). Positions in neither map are draws.
  final Map<String, int> _winIn = {};
  final Map<String, int> _lossIn = {};

  Iterable<ChopsticksState> _all() sync* {
    final pairs = [
      for (var a = 0; a <= 4; a++)
        for (var b = a; b <= 4; b++) [a, b],
    ];
    for (final p in pairs) {
      for (final q in pairs) {
        for (var turn = 0; turn < 2; turn++) {
          yield ChopsticksState(p, q, turn, rollover: rollover);
        }
      }
    }
  }

  /// Ply-by-ply retrograde analysis: a win in n needs a move into a loss in
  /// n-1; a loss in n needs every move to lead into a win of at most n-1.
  void _solve() {
    final states = {for (final s in _all()) s.key: s};
    for (final s in states.values) {
      if (s.over && s.isOut(s.turn)) _lossIn[s.key] = 0;
    }
    for (var n = 1; n < 400; n++) {
      final wins = <String>[], losses = <String>[];
      for (final s in states.values) {
        final k = s.key;
        if (s.over || _winIn.containsKey(k) || _lossIn.containsKey(k)) continue;
        var winning = false, allWins = true, worst = 0;
        for (final m in s.legalMoves()) {
          final nk = s.apply(m).key;
          if (_lossIn[nk] == n - 1) winning = true;
          final w = _winIn[nk];
          if (w == null) {
            allWins = false;
          } else {
            worst = max(worst, w);
          }
        }
        if (winning) {
          wins.add(k);
        } else if (allWins && worst == n - 1) {
          losses.add(k);
        }
      }
      if (wins.isEmpty && losses.isEmpty) break;
      for (final k in wins) {
        _winIn[k] = n;
      }
      for (final k in losses) {
        _lossIn[k] = n;
      }
    }
  }

  /// >0: the mover wins in that many plies; <0: loses in that many (a lost
  /// terminal position is -1); 0: a draw with best play.
  int valueOf(ChopsticksState s) {
    final w = _winIn[s.key];
    if (w != null) return w;
    final l = _lossIn[s.key];
    if (l != null) return l == 0 ? -1 : -l;
    return 0;
  }

  /// Fastest win, else a draw, else the slowest loss.
  ChopsticksMove? bestMove(ChopsticksState s) {
    final moves = s.legalMoves();
    if (moves.isEmpty) return null;
    ChopsticksMove best = moves.first;
    var bestScore = -1 << 30;
    for (final m in moves) {
      final nk = s.apply(m).key;
      final loss = _lossIn[nk], win = _winIn[nk];
      // From the opponent's position: their loss is our win.
      final score = loss != null
          ? 100000 - loss
          : win != null
              ? -100000 + win
              : 0;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  ChopsticksMove? randomMove(ChopsticksState s, Random random) {
    final moves = s.legalMoves();
    return moves.isEmpty ? null : moves[random.nextInt(moves.length)];
  }
}
