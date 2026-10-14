import 'dart:math';

class Domino {
  const Domino(this.a, this.b);
  final int a, b;
  int get pips => a + b;
  bool get isDouble => a == b;
  bool has(int v) => a == v || b == v;
  int other(int v) => a == v ? b : a;
  @override
  bool operator ==(Object other) =>
      other is Domino && ((other.a == a && other.b == b) || (other.a == b && other.b == a));
  @override
  int get hashCode => min(a, b) * 7 + max(a, b);
  @override
  String toString() => '[$a|$b]';
}

/// A tile on the line of play, oriented left-to-right.
class Placed {
  const Placed(this.left, this.right);
  final int left, right;
}

/// Draw dominoes (double-six) for 2–4 players. Match an open end; if you
/// cannot, draw from the boneyard until you can (or pass when it is empty).
/// The first to play all tiles scores the pips left in the other hands;
/// in a blocked game the lowest hand wins. First to 100 wins the match.
class DominoesGame {
  DominoesGame({this.players = 2, this.target = 100, Random? random}) : rng = random ?? Random() {
    scores = List.filled(players, 0);
    deal();
  }

  final int players, target;
  final Random rng;
  late List<int> scores;
  late List<List<Domino>> hands;
  late List<Domino> boneyard;
  List<Placed> line = [];
  int turn = 0;
  int passes = 0;
  int? roundWinner;
  String log = '';

  /// Values each player is known not to hold (they drew or passed on them).
  late List<Set<int>> missing;

  bool get matchOver => scores.any((s) => s >= target);
  int? get leftEnd => line.isEmpty ? null : line.first.left;
  int? get rightEnd => line.isEmpty ? null : line.last.right;

  String name(int p) => p == 0 ? 'You' : 'Player ${p + 1}';

  void deal() {
    final all = [for (var a = 0; a <= 6; a++) for (var b = a; b <= 6; b++) Domino(a, b)]..shuffle(rng);
    final n = players == 2 ? 7 : 5;
    hands = [for (var p = 0; p < players; p++) [for (var i = 0; i < n; i++) all.removeLast()]];
    boneyard = all;
    line = [];
    passes = 0;
    roundWinner = null;
    missing = List.generate(players, (_) => <int>{});
    // Highest double leads; otherwise the heaviest tile.
    var bestP = 0, bestScore = -1;
    for (var p = 0; p < players; p++) {
      for (final d in hands[p]) {
        final s = d.isDouble ? 100 + d.a : d.pips;
        if (s > bestScore) {
          bestScore = s;
          bestP = p;
        }
      }
    }
    turn = bestP;
    log = '${name(turn)} ${turn == 0 ? 'lead' : 'leads'}';
  }

  /// Which ends [d] can go on: 'L', 'R' or both.
  List<String> ends(Domino d) {
    if (line.isEmpty) return ['R'];
    return [if (d.has(leftEnd!)) 'L', if (d.has(rightEnd!)) 'R'];
  }

  List<Domino> playable(int p) => hands[p].where((d) => ends(d).isNotEmpty).toList();

  void play(Domino d, String end) {
    if (!ends(d).contains(end)) return;
    hands[turn].remove(d);
    if (line.isEmpty) {
      line.add(Placed(d.a, d.b));
    } else if (end == 'L') {
      line.insert(0, Placed(d.other(leftEnd!), leftEnd!));
    } else {
      line.add(Placed(rightEnd!, d.other(rightEnd!)));
    }
    passes = 0;
    log = '${name(turn)} played $d';
    if (hands[turn].isEmpty) {
      _endRound(turn);
      return;
    }
    turn = (turn + 1) % players;
  }

  /// Draws one tile for the current player; false if the boneyard is empty.
  bool draw() {
    if (boneyard.isEmpty) return false;
    if (line.isNotEmpty) missing[turn].addAll({leftEnd!, rightEnd!});
    hands[turn].add(boneyard.removeLast());
    log = '${name(turn)} drew a tile';
    return true;
  }

  void pass() {
    if (line.isNotEmpty) missing[turn].addAll({leftEnd!, rightEnd!});
    log = '${name(turn)} passed';
    passes++;
    if (passes >= players) {
      final totals = [for (final h in hands) h.fold(0, (s, d) => s + d.pips)];
      final low = totals.reduce(min);
      _endRound(totals.indexOf(low), blocked: true);
      return;
    }
    turn = (turn + 1) % players;
  }

  void _endRound(int winner, {bool blocked = false}) {
    final others = [
      for (var p = 0; p < players; p++)
        if (p != winner) hands[p].fold(0, (s, d) => s + d.pips)
    ].fold(0, (a, b) => a + b);
    final mine = hands[winner].fold(0, (s, d) => s + d.pips);
    final pts = blocked ? max(0, others - mine) : others;
    scores[winner] += pts;
    roundWinner = winner;
    log = blocked ? 'Blocked! ${name(winner)} had the lowest hand: +$pts' : '${name(winner)} dominoed! +$pts';
  }

  /// Computer turn: draws as needed, then plays or passes.
  void aiTurn(int level) {
    while (playable(turn).isEmpty) {
      if (!draw()) {
        pass();
        return;
      }
    }
    final options = <(Domino, String)>[
      for (final d in playable(turn))
        for (final e in ends(d)) (d, e)
    ];
    if (level == 0) {
      final (d, e) = options[rng.nextInt(options.length)];
      play(d, e);
      return;
    }
    final next = (turn + 1) % players;
    double score((Domino, String) o) {
      final (d, e) = o;
      var s = d.pips.toDouble() + (d.isDouble ? 3 : 0);
      if (level == 2) {
        // Leave an end the next player is known to lack.
        final newEnd = line.isEmpty ? d.b : d.other(e == 'L' ? leftEnd! : rightEnd!);
        if (missing[next].contains(newEnd)) s += 8;
        // Keep variety: prefer playing values we hold many of.
        s += hands[turn].where((x) => x.has(newEnd)).length * 2;
      }
      return s;
    }

    options.sort((x, y) => score(y).compareTo(score(x)));
    play(options.first.$1, options.first.$2);
  }
}
