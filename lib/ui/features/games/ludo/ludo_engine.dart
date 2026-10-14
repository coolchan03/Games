import 'dart:math';

/// Green's route around the 15×15 board as [column, row] cells: 51 track
/// squares followed by 6 home-column squares (the last one is the centre).
/// Taken from nizwar/ludo_flutter lib/constants.dart (Apache-2.0); the other
/// colours are the same route rotated a quarter turn at a time.
const List<List<int>> greenRoute = [
  [1, 6],
  [2, 6],
  [3, 6],
  [4, 6],
  [5, 6],
  [6, 5],
  [6, 4],
  [6, 3],
  [6, 2],
  [6, 1],
  [6, 0],
  [7, 0],
  [8, 0],
  [8, 1],
  [8, 2],
  [8, 3],
  [8, 4],
  [8, 5],
  [9, 6],
  [10, 6],
  [11, 6],
  [12, 6],
  [13, 6],
  [14, 6],
  [14, 7],
  [14, 8],
  [13, 8],
  [12, 8],
  [11, 8],
  [10, 8],
  [9, 8],
  [8, 9],
  [8, 10],
  [8, 11],
  [8, 12],
  [8, 13],
  [8, 14],
  [7, 14],
  [6, 14],
  [6, 13],
  [6, 12],
  [6, 11],
  [6, 10],
  [6, 9],
  [5, 8],
  [4, 8],
  [3, 8],
  [2, 8],
  [1, 8],
  [0, 8],
  [0, 7],
  [1, 7],
  [2, 7],
  [3, 7],
  [4, 7],
  [5, 7],
  [6, 7],
];

/// Star and start squares where pieces cannot be captured (same source).
const List<List<int>> safeSquares = [[6, 2], [12, 6], [8, 12], [2, 8], [8, 1], [13, 8], [6, 13], [1, 6]];

const int finishStep = 56;

/// Seat colours in turn order: green (left), yellow (top), blue (right),
/// red (bottom).
List<int> cellFor(int seat, int step) {
  var c = greenRoute[step][0], r = greenRoute[step][1];
  for (var k = 0; k < seat; k++) {
    final nc = 14 - r, nr = c;
    c = nc;
    r = nr;
  }
  return [c, r];
}

bool isSafe(List<int> cell) => safeSquares.any((s) => s[0] == cell[0] && s[1] == cell[1]);

class LudoMove {
  const LudoMove(this.piece, this.from, this.to, {this.captures = const []});
  final int piece;
  final int from;
  final int to;

  /// (seat, piece) pairs sent back to base.
  final List<(int, int)> captures;
}

/// Ludo with fair dice. A 6 is needed to leave the base, rolling a 6 or
/// capturing grants another roll, three 6s in a row forfeit the turn, and an
/// exact roll is needed to reach the centre.
class LudoGame {
  LudoGame({required this.seats, required this.computer, Random? random})
      : rng = random ?? Random(),
        steps = {for (final s in seats) s: List.filled(4, -1)},
        current = seats.first;

  /// Active seats in turn order (subset of 0..3).
  final List<int> seats;

  /// Which seats the computer plays.
  final Set<int> computer;
  final Random rng;
  final Map<int, List<int>> steps;
  int current;
  int? dice;
  int sixes = 0;
  final List<int> finishOrder = [];
  String? message;

  bool get over => finishOrder.length >= seats.length - 1;
  bool finished(int seat) => steps[seat]!.every((s) => s == finishStep);

  List<LudoMove> movesFor(int roll) {
    final moves = <LudoMove>[];
    final mine = steps[current]!;
    for (var p = 0; p < 4; p++) {
      final from = mine[p];
      int to;
      if (from == -1) {
        if (roll != 6) continue;
        to = 0;
      } else {
        to = from + roll;
        if (to > finishStep) continue;
      }
      final caps = <(int, int)>[];
      if (to < 51) {
        final cell = cellFor(current, to);
        if (!isSafe(cell)) {
          for (final s in seats) {
            if (s == current) continue;
            for (var q = 0; q < 4; q++) {
              final st = steps[s]![q];
              if (st >= 0 && st < 51) {
                final oc = cellFor(s, st);
                if (oc[0] == cell[0] && oc[1] == cell[1]) caps.add((s, q));
              }
            }
          }
        }
      }
      moves.add(LudoMove(p, from, to, captures: caps));
    }
    return moves;
  }

  List<LudoMove> get legal => dice == null ? const [] : movesFor(dice!);

  /// Rolls the die; returns false (and passes) when nothing can move.
  bool roll([int? fixed]) {
    if (over || dice != null) return false;
    dice = fixed ?? rng.nextInt(6) + 1;
    message = null;
    if (dice == 6) {
      sixes++;
      if (sixes == 3) {
        message = 'Three sixes — turn lost';
        _next();
        return false;
      }
    }
    if (legal.isEmpty) {
      _endRoll(extra: false);
      return false;
    }
    return true;
  }

  void play(LudoMove m) {
    steps[current]![m.piece] = m.to;
    for (final (s, q) in m.captures) {
      steps[s]![q] = -1;
    }
    if (finished(current) && !finishOrder.contains(current)) finishOrder.add(current);
    final extra = (dice == 6 || m.captures.isNotEmpty || m.to == finishStep) && !finished(current);
    _endRoll(extra: extra);
  }

  void _endRoll({required bool extra}) {
    final rolledSix = dice == 6;
    dice = null;
    if (over) return;
    if ((extra || rolledSix) && !finished(current)) return;
    _next();
  }

  void _next() {
    dice = null;
    sixes = 0;
    var i = seats.indexOf(current);
    do {
      i = (i + 1) % seats.length;
    } while (finished(seats[i]));
    current = seats[i];
  }

  /// Computer choice; [skill] 0..2.
  LudoMove choose(int skill) {
    final moves = legal;
    if (skill == 0 && rng.nextDouble() < .5) return moves[rng.nextInt(moves.length)];
    double score(LudoMove m) {
      var s = 0.0;
      if (m.to == finishStep) s += 100;
      s += m.captures.length * 80;
      if (m.from == -1) s += 60;
      if (m.to >= 51) s += 30;
      final cell = m.to < 51 ? cellFor(current, m.to) : null;
      if (cell != null && isSafe(cell)) s += 25;
      if (skill == 2 && cell != null && !isSafe(cell)) {
        // Danger: opponents 1-6 squares behind the landing square.
        for (final o in seats) {
          if (o == current) continue;
          for (final st in steps[o]!) {
            if (st < 0 || st >= 51) continue;
            for (var d = 1; d <= 6; d++) {
              if (st + d < 51) {
                final c = cellFor(o, st + d);
                if (c[0] == cell[0] && c[1] == cell[1]) s -= 12;
              }
            }
          }
        }
      }
      s += m.to * .3;
      return s + rng.nextDouble() * (skill == 2 ? .5 : 8);
    }
    return moves.reduce((a, b) => score(a) >= score(b) ? a : b);
  }
}
