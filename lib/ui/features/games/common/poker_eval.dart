import 'cards/card.dart';

/// Poker hand categories, weakest first.
enum HandCategory {
  highCard('High card'),
  pair('Pair'),
  twoPair('Two pair'),
  threeOfAKind('Three of a kind'),
  straight('Straight'),
  flush('Flush'),
  fullHouse('Full house'),
  fourOfAKind('Four of a kind'),
  straightFlush('Straight flush');

  const HandCategory(this.label);
  final String label;
}

/// A comparable value for a five-card poker hand. Higher [value] wins;
/// equal values split the pot.
class HandRank implements Comparable<HandRank> {
  HandRank(this.category, this.kickers)
      : value = kickers.fold(category.index, (v, k) => v * 16 + k) *
            _pow16[5 - kickers.length];

  final HandCategory category;

  /// Ranks (2..14) that break ties within a category, most significant first.
  final List<int> kickers;
  final int value;

  static const _pow16 = [1, 16, 256, 4096, 65536, 1048576];

  @override
  int compareTo(HandRank other) => value.compareTo(other.value);

  bool operator >(HandRank o) => value > o.value;

  String get label {
    if (category == HandCategory.straightFlush && kickers.first == 14) {
      return 'Royal flush';
    }
    return category.label;
  }

  @override
  String toString() => '$label $kickers';
}

/// Ranks exactly five cards.
HandRank rankFive(List<PlayingCard> cards) {
  assert(cards.length == 5);
  final values = cards.map((c) => c.rank.numericValue).toList()
    ..sort((a, b) => b - a);
  final flush = cards.every((c) => c.suit == cards[0].suit);
  final counts = <int, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final unique = counts.keys.toList()..sort((a, b) => b - a);
  int? straightHigh;
  if (unique.length == 5) {
    if (values[0] - values[4] == 4) straightHigh = values[0];
    // Wheel: A-2-3-4-5.
    if (values[0] == 14 && values[1] == 5 && values[4] == 2) straightHigh = 5;
  }
  if (straightHigh != null && flush) {
    return HandRank(HandCategory.straightFlush, [straightHigh]);
  }
  // Order groups by size, then by rank.
  final groups = unique.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : b.compareTo(a);
    });
  final shape = groups.map((g) => counts[g]!).toList();
  if (shape[0] == 4) return HandRank(HandCategory.fourOfAKind, groups);
  if (shape[0] == 3 && shape[1] == 2)
    return HandRank(HandCategory.fullHouse, groups);
  if (flush) return HandRank(HandCategory.flush, values);
  if (straightHigh != null)
    return HandRank(HandCategory.straight, [straightHigh]);
  if (shape[0] == 3) return HandRank(HandCategory.threeOfAKind, groups);
  if (shape[0] == 2 && shape[1] == 2)
    return HandRank(HandCategory.twoPair, groups);
  if (shape[0] == 2) return HandRank(HandCategory.pair, groups);
  return HandRank(HandCategory.highCard, values);
}

/// Best five-card hand from 5–7 cards.
HandRank bestHand(List<PlayingCard> cards) {
  assert(cards.length >= 5 && cards.length <= 7);
  if (cards.length == 5) return rankFive(cards);
  HandRank? best;
  final n = cards.length;
  final pick = List<PlayingCard>.filled(5, cards[0]);
  for (var a = 0; a < n; a++) {
    for (var b = a + 1; b < n; b++) {
      for (var c = b + 1; c < n; c++) {
        for (var d = c + 1; d < n; d++) {
          for (var e = d + 1; e < n; e++) {
            pick[0] = cards[a];
            pick[1] = cards[b];
            pick[2] = cards[c];
            pick[3] = cards[d];
            pick[4] = cards[e];
            final r = rankFive(pick);
            if (best == null || r.value > best.value) best = r;
          }
        }
      }
    }
  }
  return best!;
}
