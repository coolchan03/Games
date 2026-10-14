import 'dart:math';

/// Liar's Dice (common rules): everyone rolls hidden dice. Bids claim at
/// least Q dice showing face F among all players; ones are wild. Each bid
/// must raise the quantity, or keep it and raise the face. Calling "Liar"
/// reveals the dice: the loser of the challenge loses a die.
class LiarsDiceGame {
  LiarsDiceGame({this.players = 4, this.startDice = 5, Random? random}) : rng = random ?? Random() {
    dice = List.generate(players, (_) => <int>[]);
    counts = List.filled(players, startDice);
    newRound(0);
  }

  final int players, startDice;
  final Random rng;
  late List<List<int>> dice;
  late List<int> counts;
  int turn = 0;
  (int, int)? bid; // (quantity, face)
  int? bidder;
  String log = '';
  bool revealing = false;

  int get totalDice => counts.fold(0, (a, b) => a + b);
  bool alive(int p) => counts[p] > 0;
  int? get winner => [for (var p = 0; p < players; p++) if (alive(p)) p].length == 1
      ? [for (var p = 0; p < players; p++) if (alive(p)) p].first
      : null;

  String name(int p) => p == 0 ? 'You' : 'Player ${p + 1}';

  void newRound(int starter) {
    for (var p = 0; p < players; p++) {
      dice[p] = [for (var i = 0; i < counts[p]; i++) rng.nextInt(6) + 1]..sort();
    }
    bid = null;
    bidder = null;
    revealing = false;
    turn = starter;
    while (!alive(turn)) {
      turn = (turn + 1) % players;
    }
  }

  int _next(int p) {
    var q = (p + 1) % players;
    while (!alive(q)) {
      q = (q + 1) % players;
    }
    return q;
  }

  bool validBid(int q, int f) {
    if (f < 2 || f > 6 || q < 1 || q > totalDice) return false;
    final b = bid;
    if (b == null) return true;
    return q > b.$1 || (q == b.$1 && f > b.$2);
  }

  void makeBid(int q, int f) {
    if (!validBid(q, f)) return;
    bid = (q, f);
    bidder = turn;
    log = '${name(turn)} bid $q × $f${q == 1 ? '' : 's'}';
    turn = _next(turn);
  }

  int countFace(int f) => [for (final d in dice) ...d].where((x) => x == f || x == 1).length;

  /// Current player challenges the last bid. Returns the loser.
  int challenge() {
    final (q, f) = bid!;
    final actual = countFace(f);
    final loser = actual >= q ? turn : bidder!;
    log = '${name(turn)} called liar on $q × $f. There ${actual == 1 ? 'was' : 'were'} $actual. '
        '${name(loser)} lose${loser == 0 ? '' : 's'} a die.';
    counts[loser]--;
    revealing = true;
    return loser;
  }

  void nextRound(int loser) {
    newRound(alive(loser) ? loser : _next(loser));
  }

  /// Probability that at least [q] of the unseen [unknown] dice plus
  /// [known] matching ones show face (ones wild): p = 1/3 per die.
  static double atLeast(int q, int known, int unknown) {
    final need = q - known;
    if (need <= 0) return 1;
    if (need > unknown) return 0;
    var p = 0.0;
    for (var k = need; k <= unknown; k++) {
      p += _choose(unknown, k) * pow(1 / 3, k) * pow(2 / 3, unknown - k);
    }
    return p;
  }

  static double _choose(int n, int k) {
    var r = 1.0;
    for (var i = 1; i <= k; i++) {
      r = r * (n - k + i) / i;
    }
    return r;
  }

  /// Computer decision: returns null to challenge, else a bid.
  (int, int)? aiDecide(int level) {
    final mine = dice[turn];
    final unknown = totalDice - mine.length;
    int known(int f) => mine.where((x) => x == f || x == 1).length;
    final b = bid;
    if (b != null) {
      final p = atLeast(b.$1, known(b.$2), unknown);
      final threshold = [0.25, 0.4, 0.45][level];
      if (p < threshold) return null;
    }
    // Candidate bids: raise quantity by one for each face or same quantity
    // with a higher face; choose the most likely.
    final options = <(int, int)>[];
    final baseQ = b?.$1 ?? max(1, totalDice ~/ 4);
    for (var f = 2; f <= 6; f++) {
      for (var q = baseQ; q <= baseQ + 2; q++) {
        if (validBid(q, f)) options.add((q, f));
      }
    }
    if (options.isEmpty) return null;
    double likelihood((int, int) o) => atLeast(o.$1, known(o.$2), unknown) + (level == 0 ? rng.nextDouble() * .5 : 0);
    options.sort((x, y) => likelihood(y).compareTo(likelihood(x)));
    // Occasional bluff on harder levels.
    if (level == 2 && rng.nextDouble() < .1 && options.length > 2) return options[1];
    final best = options.first;
    if (b != null && atLeast(best.$1, known(best.$2), unknown) < .3 && level > 0) return null;
    return best;
  }
}
