import 'dart:math';

import '../common/cards/card.dart';

int ginValue(PlayingCard c) => c.rank == Rank.ace ? 1 : min(10, c.rank.numericValue);
int _low(PlayingCard c) => c.rank == Rank.ace ? 1 : c.rank.numericValue;

/// Best arrangement of [cards] into melds, minimising deadwood.
class MeldResult {
  MeldResult(this.melds, this.deadwood);
  final List<List<PlayingCard>> melds;
  final List<PlayingCard> deadwood;
  int get points => deadwood.fold(0, (s, c) => s + ginValue(c));
}

List<List<PlayingCard>> _candidateMelds(List<PlayingCard> cards) {
  final melds = <List<PlayingCard>>[];
  for (final r in Rank.values) {
    final same = cards.where((c) => c.rank == r).toList();
    if (same.length >= 3) {
      melds.add(same);
      if (same.length == 4) {
        for (var skip = 0; skip < 4; skip++) {
          melds.add([for (var i = 0; i < 4; i++) if (i != skip) same[i]]);
        }
      }
    }
  }
  for (final s in Suit.values) {
    final suited = cards.where((c) => c.suit == s).toList()..sort((a, b) => _low(a) - _low(b));
    for (var i = 0; i < suited.length; i++) {
      final run = [suited[i]];
      for (var j = i + 1; j < suited.length; j++) {
        if (_low(suited[j]) != _low(run.last) + 1) break;
        run.add(suited[j]);
        if (run.length >= 3) melds.add(List.of(run));
      }
    }
  }
  return melds;
}

MeldResult bestMelds(List<PlayingCard> cards) {
  final candidates = _candidateMelds(cards);
  var best = MeldResult([], List.of(cards));
  void search(int from, List<List<PlayingCard>> chosen, Set<PlayingCard> used) {
    final dead = cards.where((c) => !used.contains(c)).toList();
    final pts = dead.fold(0, (s, c) => s + ginValue(c));
    if (pts < best.points) best = MeldResult(List.of(chosen), dead);
    for (var i = from; i < candidates.length; i++) {
      final m = candidates[i];
      if (m.any(used.contains)) continue;
      chosen.add(m);
      used.addAll(m);
      search(i + 1, chosen, used);
      chosen.removeLast();
      used.removeAll(m);
    }
  }

  search(0, [], {});
  return best;
}

enum GinPhase { draw, discard, handOver }

class HandResult {
  HandResult(this.text, this.points, this.winner);
  final String text;
  final int points;
  final int? winner;
}

class GinRummyGame {
  GinRummyGame({Random? random, this.target = 100}) : rng = random ?? Random() {
    deal();
  }

  final Random rng;
  final int target;
  final scores = [0, 0];
  late List<List<PlayingCard>> hands;
  late List<PlayingCard> stock;
  late List<PlayingCard> discard;
  int turn = 0;
  int dealer = 1;
  GinPhase phase = GinPhase.draw;
  HandResult? result;
  List<PlayingCard> laidOff = [];

  /// Cards the opponent took from the discard pile (the computer watches these).
  final Set<PlayingCard> takenByHuman = {};

  bool get matchOver => scores.any((s) => s >= target);

  void deal() {
    final deck = standardDeckCards()..shuffle(rng);
    hands = [for (var p = 0; p < 2; p++) [for (var i = 0; i < 10; i++) deck.removeLast()]];
    discard = [deck.removeLast()];
    stock = deck;
    dealer = 1 - dealer;
    turn = 1 - dealer;
    phase = GinPhase.draw;
    result = null;
    laidOff = [];
    takenByHuman.clear();
  }

  void drawStock() {
    if (phase != GinPhase.draw) return;
    hands[turn].add(stock.removeLast());
    phase = GinPhase.discard;
  }

  void drawDiscard() {
    if (phase != GinPhase.draw || discard.isEmpty) return;
    final c = discard.removeLast();
    if (turn == 0) takenByHuman.add(c);
    hands[turn].add(c);
    phase = GinPhase.discard;
  }

  int deadwoodWithout(int p, PlayingCard c) =>
      bestMelds(hands[p].where((x) => x != c).toList()).points;

  bool canKnock(PlayingCard c) => phase == GinPhase.discard && deadwoodWithout(turn, c) <= 10;

  void discardCard(PlayingCard c, {bool knock = false}) {
    if (phase != GinPhase.discard) return;
    hands[turn].remove(c);
    discard.add(c);
    if (knock && bestMelds(hands[turn]).points <= 10) {
      _settle(turn);
      return;
    }
    if (stock.length <= 2) {
      result = HandResult('The stock ran out — no score this hand.', 0, null);
      phase = GinPhase.handOver;
      return;
    }
    turn = 1 - turn;
    phase = GinPhase.draw;
  }

  bool _extends(List<PlayingCard> meld, PlayingCard c) {
    final isSet = meld.every((m) => m.rank == meld.first.rank);
    if (isSet) return c.rank == meld.first.rank && meld.length < 4;
    if (c.suit != meld.first.suit) return false;
    final lows = meld.map(_low).toList()..sort();
    return _low(c) == lows.first - 1 || _low(c) == lows.last + 1;
  }

  void _settle(int knocker) {
    final defender = 1 - knocker;
    final k = bestMelds(hands[knocker]);
    final d = bestMelds(hands[defender]);
    final gin = k.points == 0;
    var defDead = List.of(d.deadwood);
    final knockerMelds = [for (final m in k.melds) List.of(m)];
    laidOff = [];
    if (!gin) {
      var changed = true;
      while (changed) {
        changed = false;
        for (final c in defDead.toList()) {
          for (final m in knockerMelds) {
            if (_extends(m, c)) {
              m.add(c);
              defDead.remove(c);
              laidOff.add(c);
              changed = true;
              break;
            }
          }
        }
      }
    }
    final dp = defDead.fold(0, (s, c) => s + ginValue(c));
    String who(int p) => p == 0 ? 'You' : 'Computer';
    if (gin) {
      final pts = 25 + dp;
      scores[knocker] += pts;
      result = HandResult('${who(knocker)} went gin! +$pts', pts, knocker);
    } else if (dp <= k.points) {
      final pts = 25 + k.points - dp;
      scores[defender] += pts;
      result = HandResult('Undercut! ${who(defender)} score${defender == 0 ? '' : 's'} $pts '
          '(deadwood ${k.points} vs $dp)', pts, defender);
    } else {
      final pts = dp - k.points;
      scores[knocker] += pts;
      result = HandResult('${who(knocker)} knocked: +$pts (deadwood ${k.points} vs $dp)', pts, knocker);
    }
    phase = GinPhase.handOver;
  }

  /// Computer plays a whole turn. [level] 0..2.
  void aiTurn(int level) {
    final me = turn;
    final current = bestMelds(hands[me]).points;
    // Draw decision: take the upcard if it improves our best hand.
    final up = discard.last;
    final withUp = [...hands[me], up];
    var bestAfterUp = 1 << 30;
    for (final c in withUp) {
      if (c == up) continue;
      bestAfterUp = min(bestAfterUp, bestMelds(withUp.where((x) => x != c).toList()).points);
    }
    final takeUp = level == 0 ? bestAfterUp + 4 < current : bestAfterUp < current - (level == 2 ? 0 : 2);
    if (takeUp) {
      drawDiscard();
    } else {
      drawStock();
    }
    // Discard decision.
    final hand = hands[me];
    PlayingCard? choice;
    var bestScore = 1 << 30;
    for (final c in hand) {
      if (takeUp && c == up && hand.length > 1) continue;
      var score = deadwoodWithout(me, c) * 10 - ginValue(c);
      if (level == 2) {
        // Avoid feeding the opponent: same rank or suit neighbours of cards
        // they picked up.
        for (final t in takenByHuman) {
          if (t.rank == c.rank || (t.suit == c.suit && (_low(t) - _low(c)).abs() <= 2)) score += 25;
        }
      }
      if (level == 0) score += rng.nextInt(60);
      if (score < bestScore) {
        bestScore = score;
        choice = c;
      }
    }
    final after = deadwoodWithout(me, choice!);
    final knockAt = [10, 10, stock.length < 12 ? 10 : 6][level];
    discardCard(choice, knock: after <= knockAt);
  }
}
