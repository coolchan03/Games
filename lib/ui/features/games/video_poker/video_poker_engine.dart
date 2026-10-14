import 'dart:math';

import '../common/cards/card.dart';
import '../common/poker_eval.dart';

/// Standard 9/6 Jacks or Better pay table (credits per credit bet).
const jacksOrBetterPays = <String, int>{
  'Royal flush': 800,
  'Straight flush': 50,
  'Four of a kind': 25,
  'Full house': 9,
  'Flush': 6,
  'Straight': 4,
  'Three of a kind': 3,
  'Two pair': 2,
  'Jacks or better': 1,
};

/// Pay-table name for a final five-card hand, or null for no win.
String? payoutName(List<PlayingCard> hand) {
  final r = rankFive(hand);
  switch (r.category) {
    case HandCategory.straightFlush:
      return r.kickers.first == 14 ? 'Royal flush' : 'Straight flush';
    case HandCategory.fourOfAKind:
      return 'Four of a kind';
    case HandCategory.fullHouse:
      return 'Full house';
    case HandCategory.flush:
      return 'Flush';
    case HandCategory.straight:
      return 'Straight';
    case HandCategory.threeOfAKind:
      return 'Three of a kind';
    case HandCategory.twoPair:
      return 'Two pair';
    case HandCategory.pair:
      return r.kickers.first >= 11 ? 'Jacks or better' : null;
    case HandCategory.highCard:
      return null;
  }
}

int payout(List<PlayingCard> hand, int bet) {
  final name = payoutName(hand);
  if (name == null) return 0;
  // Max bet royal pays the famous 4000.
  if (name == 'Royal flush' && bet == 5) return 4000;
  return jacksOrBetterPays[name]! * bet;
}

class VideoPokerGame {
  VideoPokerGame({Random? random}) : rng = random ?? Random();
  final Random rng;
  int credits = 200;
  int bet = 5;
  List<PlayingCard> deck = [];
  List<PlayingCard> hand = [];
  List<bool> held = List.filled(5, false);
  bool drawn = true;
  int lastWin = 0;

  bool get canDeal => drawn && credits >= bet;

  void deal() {
    if (!canDeal) return;
    credits -= bet;
    deck = standardDeckCards()..shuffle(rng);
    hand = [for (var i = 0; i < 5; i++) deck.removeLast()];
    held = List.filled(5, false);
    drawn = false;
    lastWin = 0;
  }

  void toggle(int i) {
    if (!drawn) held[i] = !held[i];
  }

  void draw() {
    if (drawn) return;
    for (var i = 0; i < 5; i++) {
      if (!held[i]) hand[i] = deck.removeLast();
    }
    drawn = true;
    lastWin = payout(hand, bet);
    credits += lastWin;
  }

  /// Exhaustive expected-value hold advice over all 32 hold patterns
  /// (sampled for patterns that draw 3+ cards to stay fast on the web).
  List<bool> bestHold({int samples = 400}) {
    final remaining = deck.toList();
    var bestEv = -1.0;
    var best = List.filled(5, false);
    for (var mask = 0; mask < 32; mask++) {
      final hold = [for (var i = 0; i < 5; i++) (mask >> i) & 1 == 1];
      final kept = [for (var i = 0; i < 5; i++) if (hold[i]) hand[i]];
      final need = 5 - kept.length;
      double ev;
      if (need == 0) {
        ev = payout(kept, 1).toDouble();
      } else if (need <= 2) {
        var total = 0, n = 0;
        if (need == 1) {
          for (final c in remaining) {
            total += payout([...kept, c], 1);
            n++;
          }
        } else {
          for (var a = 0; a < remaining.length; a++) {
            for (var b = a + 1; b < remaining.length; b++) {
              total += payout([...kept, remaining[a], remaining[b]], 1);
              n++;
            }
          }
        }
        ev = total / n;
      } else {
        var total = 0;
        final pool = remaining.toList();
        for (var s = 0; s < samples; s++) {
          pool.shuffle(rng);
          total += payout([...kept, ...pool.take(need)], 1);
        }
        ev = total / samples;
      }
      if (ev > bestEv + 1e-9) {
        bestEv = ev;
        best = hold;
      }
    }
    return best;
  }
}
