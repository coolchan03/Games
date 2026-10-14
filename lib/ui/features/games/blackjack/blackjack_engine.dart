import 'dart:math';

import '../common/cards/card.dart';

int cardValue(PlayingCard c) =>
    c.rank == Rank.ace ? 11 : min(10, c.rank.numericValue);

/// (total, soft) for a blackjack hand.
(int, bool) handTotal(List<PlayingCard> cards) {
  var total = 0, aces = 0;
  for (final c in cards) {
    total += cardValue(c);
    if (c.rank == Rank.ace) aces++;
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  return (total, aces > 0);
}

class BjHand {
  BjHand(this.cards, this.bet, {this.fromSplit = false});
  final List<PlayingCard> cards;
  int bet;
  bool fromSplit;
  bool done = false;
  bool doubled = false;
  String outcome = '';

  int get total => handTotal(cards).$1;
  bool get soft => handTotal(cards).$2;
  bool get bust => total > 21;
  bool get blackjack => cards.length == 2 && total == 21 && !fromSplit;
}

/// Blackjack for virtual chips: six-deck shoe, dealer stands on soft 17,
/// blackjack pays 3:2, double on any two cards, one split per hand (split
/// aces receive one card each).
class BlackjackGame {
  BlackjackGame({Random? random, this.decks = 6}) : rng = random ?? Random() {
    _shuffle();
  }

  final Random rng;
  final int decks;
  int chips = 1000;
  int bet = 50;
  List<PlayingCard> shoe = [];
  List<PlayingCard> dealer = [];
  List<BjHand> hands = [];
  int active = 0;
  bool inRound = false;
  String summary = '';

  void _shuffle() {
    shoe = [for (var d = 0; d < decks; d++) ...standardDeckCards()]..shuffle(rng);
  }

  PlayingCard _draw() {
    if (shoe.length < 15) _shuffle();
    return shoe.removeLast();
  }

  BjHand get hand => hands[active];

  bool get canDeal => !inRound && chips >= bet;

  void deal() {
    if (!canDeal) return;
    if (shoe.length < decks * 52 ~/ 4) _shuffle();
    chips -= bet;
    hands = [BjHand([_draw()], bet)];
    active = 0;
    dealer = [_draw()];
    hand.cards.add(_draw());
    dealer.add(_draw());
    inRound = true;
    summary = '';
    final dealerBj = handTotal(dealer).$1 == 21;
    if (hand.blackjack || dealerBj) _finish();
  }

  bool get canDouble => inRound && hand.cards.length == 2 && chips >= hand.bet && !hand.done;
  bool get canSplit =>
      inRound &&
      hands.length == 1 &&
      hand.cards.length == 2 &&
      cardValue(hand.cards[0]) == cardValue(hand.cards[1]) &&
      chips >= hand.bet;

  void hit() {
    if (!inRound) return;
    hand.cards.add(_draw());
    if (hand.total >= 21) _next();
  }

  void stand() {
    if (!inRound) return;
    _next();
  }

  void doubleDown() {
    if (!canDouble) return;
    chips -= hand.bet;
    hand.bet *= 2;
    hand.doubled = true;
    hand.cards.add(_draw());
    _next();
  }

  void split() {
    if (!canSplit) return;
    chips -= hand.bet;
    final second = hand.cards.removeLast();
    final aces = second.rank == Rank.ace;
    hand.fromSplit = true;
    hands.add(BjHand([second], hand.bet, fromSplit: true));
    hands[0].cards.add(_draw());
    hands[1].cards.add(_draw());
    if (aces) {
      for (final h in hands) {
        h.done = true;
      }
      _finish();
    } else if (hand.total == 21) {
      _next();
    }
  }

  void _next() {
    hand.done = true;
    while (active < hands.length && hands[active].done) {
      active++;
    }
    if (active >= hands.length) {
      active = hands.length - 1;
      _finish();
    } else if (hand.total == 21) {
      _next();
    }
  }

  void _finish() {
    final allBust = hands.every((h) => h.bust);
    final dealerBj = dealer.length == 2 && handTotal(dealer).$1 == 21;
    if (!allBust && !dealerBj && !(hands.length == 1 && hands[0].blackjack)) {
      while (handTotal(dealer).$1 < 17) {
        dealer.add(_draw());
      }
    }
    final d = handTotal(dealer).$1;
    var net = 0;
    for (final h in hands) {
      int payout;
      if (h.bust) {
        payout = 0;
        h.outcome = 'Bust';
      } else if (h.blackjack && !dealerBj) {
        payout = h.bet + h.bet * 3 ~/ 2;
        h.outcome = 'Blackjack!';
      } else if (dealerBj && !h.blackjack) {
        payout = 0;
        h.outcome = 'Dealer blackjack';
      } else if (d > 21 || h.total > d) {
        payout = h.bet * 2;
        h.outcome = 'Win';
      } else if (h.total == d) {
        payout = h.bet;
        h.outcome = 'Push';
      } else {
        payout = 0;
        h.outcome = 'Lose';
      }
      chips += payout;
      net += payout - h.bet;
      h.done = true;
    }
    summary = net > 0 ? 'You win $net' : net < 0 ? 'You lose ${-net}' : 'Push';
    inRound = false;
  }

  /// Basic strategy (multi-deck, S17, double after split not assumed).
  String advice() {
    if (!inRound) return '';
    final up = cardValue(dealer.first);
    final (total, soft) = handTotal(hand.cards);
    final two = hand.cards.length == 2;
    if (canSplit) {
      final v = cardValue(hand.cards[0]);
      final split = switch (v) {
        11 || 8 => true,
        10 || 5 => false,
        9 => up != 7 && up < 10,
        7 => up <= 7,
        6 => up >= 3 && up <= 6,
        4 => false,
        _ => up >= 4 && up <= 7, // 2s and 3s
      };
      if (split) return 'Split';
    }
    if (soft && total <= 21) {
      if (total >= 19) return 'Stand';
      if (total == 18) {
        if (two && up >= 3 && up <= 6) return 'Double';
        return up >= 9 ? 'Hit' : 'Stand';
      }
      final doubleUps = switch (total) { 17 => [3, 4, 5, 6], 15 || 16 => [4, 5, 6], _ => [5, 6] };
      return two && doubleUps.contains(up) ? 'Double' : 'Hit';
    }
    if (total >= 17) return 'Stand';
    if (total >= 13) return up <= 6 ? 'Stand' : 'Hit';
    if (total == 12) return up >= 4 && up <= 6 ? 'Stand' : 'Hit';
    if (total == 11) return two ? 'Double' : 'Hit';
    if (total == 10) return two && up <= 9 ? 'Double' : 'Hit';
    if (total == 9) return two && up >= 3 && up <= 6 ? 'Double' : 'Hit';
    return 'Hit';
  }
}
