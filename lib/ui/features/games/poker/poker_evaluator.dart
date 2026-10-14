import '../shared/playing_cards.dart';
import 'phe_tables.dart';

/// Adapted from thlorenz/phe evaluator5.js and hash.js, MIT (Thorsten Lorenz).
/// Uses only the small five-card tables; six/seven-card hands enumerate subsets.
/// A smaller rank is stronger. Ties are exact, including all relevant kickers.
class PokerRank implements Comparable<PokerRank> {
  final int value;
  const PokerRank(this.value);
  String get name {
    if (value <= 10) return value == 1 ? 'Royal flush' : 'Straight flush';
    if (value <= 166) return 'Four of a kind';
    if (value <= 322) return 'Full house';
    if (value <= 1599) return 'Flush';
    if (value <= 1609) return 'Straight';
    if (value <= 2467) return 'Three of a kind';
    if (value <= 3325) return 'Two pair';
    if (value <= 6185) return 'One pair';
    return 'High card';
  }
  @override
  int compareTo(PokerRank other) => value.compareTo(other.value);
}

PokerRank evaluatePoker(List<PlayingCard> cards) {
  if (cards.length < 5 || cards.length > 7 || cards.toSet().length != cards.length) {
    throw ArgumentError('Poker requires five to seven distinct cards');
  }
  var best = 7463;
  final hand = <PlayingCard>[];
  void choose(int start) {
    if (hand.length == 5) {
      final value = _evaluateFive(hand);
      if (value < best) best = value;
      return;
    }
    for (var i = start; i <= cards.length - (5 - hand.length); i++) {
      hand.add(cards[i]); choose(i + 1); hand.removeLast();
    }
  }
  choose(0);
  return PokerRank(best);
}

int _evaluateFive(List<PlayingCard> cards) {
  final ranks = List<int>.filled(13, 0);
  var mask = 0;
  var flush = true;
  for (final card in cards) {
    ranks[card.rank - 2]++;
    mask |= 1 << (card.rank - 2);
    if (card.suit != cards.first.suit) flush = false;
  }
  if (flush) return pheFlush[mask];
  var hash = 0, remaining = 5;
  for (var i = 0; i < 13; i++) {
    hash += pheDp[ranks[i]][12 - i][remaining];
    remaining -= ranks[i];
    if (remaining == 0) break;
  }
  return pheNoflush5[hash];
}
