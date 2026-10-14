import 'dart:math';

import '../common/cards/card.dart';

int pipValue(PlayingCard c) => c.rank == Rank.ace ? 1 : min(10, c.rank.numericValue);
int runRank(PlayingCard c) => c.rank == Rank.ace ? 1 : c.rank.numericValue;

/// Points for a four-card hand (or crib) with the starter.
int scoreShow(List<PlayingCard> hand, PlayingCard starter, {bool crib = false}) {
  final all = [...hand, starter];
  var points = 0;
  // Fifteens: every subset summing to 15.
  for (var mask = 1; mask < 32; mask++) {
    var sum = 0;
    for (var i = 0; i < 5; i++) {
      if (mask & (1 << i) != 0) sum += pipValue(all[i]);
    }
    if (sum == 15) points += 2;
  }
  // Pairs.
  for (var i = 0; i < 5; i++) {
    for (var j = i + 1; j < 5; j++) {
      if (all[i].rank == all[j].rank) points += 2;
    }
  }
  // Runs: count the longest run length and its multiplicity.
  final counts = List.filled(14, 0);
  for (final c in all) {
    counts[runRank(c)]++;
  }
  var bestLen = 0, bestMult = 0;
  for (var start = 1; start <= 13; start++) {
    var len = 0, mult = 1;
    while (start + len <= 13 && counts[start + len] > 0) {
      mult *= counts[start + len];
      len++;
    }
    if (len >= 3 && len > bestLen) {
      bestLen = len;
      bestMult = mult;
    }
  }
  points += bestLen * bestMult;
  // Flush.
  if (hand.every((c) => c.suit == hand.first.suit)) {
    if (starter.suit == hand.first.suit) {
      points += 5;
    } else if (!crib) {
      points += 4;
    }
  }
  // Nobs: jack of the starter's suit.
  if (hand.any((c) => c.rank == Rank.jack && c.suit == starter.suit)) points += 1;
  return points;
}

/// Points for the card just played onto [pile] (which already includes it).
int peggingScore(List<PlayingCard> pile) {
  final count = pile.fold(0, (s, c) => s + pipValue(c));
  var points = 0;
  if (count == 15 || count == 31) points += 2;
  // Pairs at the end of the pile.
  var same = 1;
  for (var i = pile.length - 2; i >= 0 && pile[i].rank == pile.last.rank; i--) {
    same++;
  }
  points += switch (same) { 2 => 2, 3 => 6, 4 => 12, _ => 0 };
  // Runs formed by the last k cards, any order.
  for (var k = pile.length; k >= 3; k--) {
    final tail = pile.sublist(pile.length - k).map(runRank).toList()..sort();
    var run = true;
    for (var i = 1; i < tail.length; i++) {
      if (tail[i] != tail[i - 1] + 1) {
        run = false;
        break;
      }
    }
    if (run) {
      points += k;
      break;
    }
  }
  return points;
}

enum CribPhase { discard, pegging, show, gameOver }

class CribbageGame {
  CribbageGame({Random? random}) : rng = random ?? Random() {
    dealer = rng.nextInt(2);
    _deal();
  }

  final Random rng;
  final scores = [0, 0];
  late int dealer;
  late List<List<PlayingCard>> hands; // kept hands for the show
  late List<List<PlayingCard>> pegHands; // cards left to peg
  List<PlayingCard> crib = [];
  PlayingCard? starter;
  CribPhase phase = CribPhase.discard;
  List<PlayingCard> pile = [];
  int count = 0;
  int turn = 0;
  final goSaid = [false, false];
  String log = '';
  List<String> showLog = [];

  int? get winner => scores[0] >= 121 ? 0 : scores[1] >= 121 ? 1 : null;
  String name(int p) => p == 0 ? 'You' : 'Computer';

  void _deal() {
    final deck = standardDeckCards()..shuffle(rng);
    hands = [for (var p = 0; p < 2; p++) [for (var i = 0; i < 6; i++) deck.removeLast()]];
    _deck = deck;
    crib = [];
    starter = null;
    pile = [];
    count = 0;
    goSaid.fillRange(0, 2, false);
    phase = CribPhase.discard;
    showLog = [];
    log = '${name(dealer)} ${dealer == 0 ? 'deal' : 'deals'}. Choose two cards for ${dealer == 0 ? 'your' : 'the computer\'s'} crib.';
  }

  late List<PlayingCard> _deck;

  void _peg(int p, int pts, String why) {
    if (pts <= 0 || winner != null) return;
    scores[p] = min(121, scores[p] + pts);
    log = '${name(p)} ${p == 0 ? 'peg' : 'pegs'} $pts for $why';
    if (winner != null) phase = CribPhase.gameOver;
  }

  /// Both players discard two cards; the human's choice is [mine].
  void discard(List<PlayingCard> mine, int level) {
    if (phase != CribPhase.discard || mine.length != 2 ||
        mine.toSet().length != 2 ||
        mine.any((card) => !hands[0].contains(card))) return;
    final theirs = aiDiscard(hands[1], dealer == 1, level);
    for (final c in mine) {
      hands[0].remove(c);
    }
    for (final c in theirs) {
      hands[1].remove(c);
    }
    crib = [...mine, ...theirs];
    starter = _deck.removeLast();
    if (starter!.rank == Rank.jack) _peg(dealer, 2, 'his heels (jack starter)');
    pegHands = [List.of(hands[0]), List.of(hands[1])];
    phase = winner == null ? CribPhase.pegging : CribPhase.gameOver;
    turn = 1 - dealer;
  }

  bool canPlay(int p, PlayingCard c) => count + pipValue(c) <= 31;
  bool hasPlay(int p) => pegHands[p].any((c) => canPlay(p, c));

  void play(PlayingCard c) {
    if (phase != CribPhase.pegging ||
        !pegHands[turn].contains(c) || !canPlay(turn, c)) return;
    pegHands[turn].remove(c);
    pile.add(c);
    count += pipValue(c);
    log = '${name(turn)} played ${c.symbolString()} — count $count';
    _peg(turn, peggingScore(pile), count == 31 ? '31' : count == 15 ? 'fifteen' : 'pairs/runs');
    if (count == 31) {
      _resetCount();
      turn = 1 - turn;
      if (pegHands[turn].isEmpty) turn = 1 - turn;
    } else {
      _advance(lastPlayer: turn);
    }
    _checkEnd();
  }

  void _resetCount() {
    pile = [];
    count = 0;
    goSaid.fillRange(0, 2, false);
  }

  void _advance({required int lastPlayer}) {
    final other = 1 - lastPlayer;
    if (hasPlay(other)) {
      turn = other;
    } else if (hasPlay(lastPlayer)) {
      turn = lastPlayer; // other says "go"
    } else {
      // Nobody can play: last card scores 1 (31 already scored 2).
      _peg(lastPlayer, 1, 'last card');
      _resetCount();
      turn = other;
      if (pegHands[turn].isEmpty) turn = lastPlayer;
    }
  }

  void _checkEnd() {
    if (phase == CribPhase.gameOver) return;
    // The last-card point was already credited by _advance.
    if (pegHands[0].isEmpty && pegHands[1].isEmpty) _show();
  }

  void _show() {
    phase = CribPhase.show;
    final pone = 1 - dealer;
    showLog = [];
    for (final (p, cards, isCrib) in [(pone, hands[pone], false), (dealer, hands[dealer], false), (dealer, crib, true)]) {
      if (winner != null) break;
      final pts = scoreShow(cards, starter!, crib: isCrib);
      scores[p] = min(121, scores[p] + pts);
      showLog.add('${name(p)} ${isCrib ? 'crib' : 'hand'}: $pts');
    }
    if (winner != null) phase = CribPhase.gameOver;
  }

  void nextHand() {
    if (phase != CribPhase.show) return;
    dealer = 1 - dealer;
    _deal();
  }

  /// Chooses two cards for the crib maximising expected hand value.
  List<PlayingCard> aiDiscard(List<PlayingCard> six, bool ownCrib, int level) {
    if (level == 0) {
      final s = List.of(six)..shuffle(rng);
      return s.take(2).toList();
    }
    final unseen = standardDeckCards().where((c) => !six.contains(c)).toList();
    List<PlayingCard>? best;
    var bestValue = -1e9;
    for (var a = 0; a < 6; a++) {
      for (var b = a + 1; b < 6; b++) {
        final keep = [for (var i = 0; i < 6; i++) if (i != a && i != b) six[i]];
        var total = 0;
        for (final s in unseen) {
          total += scoreShow(keep, s);
        }
        var value = total / unseen.length;
        // Crib cards: fives and pairs help whoever owns the crib.
        final d = [six[a], six[b]];
        var cribGuess = 0.0;
        if (pipValue(d[0]) + pipValue(d[1]) == 15) cribGuess += 2;
        if (d[0].rank == d[1].rank) cribGuess += 2;
        cribGuess += d.where((c) => c.rank == Rank.five).length * 1.5;
        if (level == 2) value += ownCrib ? cribGuess : -cribGuess;
        if (value > bestValue) {
          bestValue = value;
          best = d;
        }
      }
    }
    return best!;
  }

  PlayingCard aiPeg(int level) {
    final options = pegHands[turn].where((c) => canPlay(turn, c)).toList();
    if (level == 0) return options[rng.nextInt(options.length)];
    PlayingCard? best;
    var bestScore = -1e9;
    for (final c in options) {
      final after = [...pile, c];
      final newCount = count + pipValue(c);
      var s = peggingScore(after) * 10.0;
      if (level == 2) {
        if (newCount == 5 || newCount == 21) s -= 6; // easy 15 / 31 for opponent
        if (pile.isNotEmpty && (pile.last.rank.index - c.rank.index).abs() == 1) s -= 2; // run bait
      }
      s += pipValue(c) * .1; // keep low cards for later
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best!;
  }
}
