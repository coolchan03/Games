import 'package:flutter/material.dart';

import 'card_view.dart';
import 'cards/card.dart';

/// A card in a solitaire layout that may be face down.
class SCard {
  SCard(this.card, {this.up = false});
  final PlayingCard card;
  bool up;

  SCard copy() => SCard(card, up: up);
  Rank get rank => card.rank;
  Suit get suit => card.suit;
  bool get red => card.suit == Suit.hearts || card.suit == Suit.diamonds;

  /// Ace = 1 … King = 13.
  int get value => card.rank == Rank.ace ? 1 : card.rank.numericValue;
}

List<List<SCard>> copyPiles(List<List<SCard>> piles) =>
    [for (final p in piles) [for (final c in p) c.copy()]];

/// Ace-low rank value of a plain card.
int aceLow(PlayingCard c) => c.rank == Rank.ace ? 1 : c.rank.numericValue;

/// Fixed-width column of overlapping cards (tableau pile).
class CardColumn extends StatelessWidget {
  const CardColumn({
    super.key,
    required this.cards,
    required this.width,
    this.selectedFrom,
    this.onTapCard,
    this.onTapEmpty,
    this.maxHeight,
    this.highlight = false,
  });

  final List<SCard> cards;
  final double width;
  final int? selectedFrom;
  final void Function(int index)? onTapCard;
  final VoidCallback? onTapEmpty;
  final double? maxHeight;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final h = width * 1.4;
    var downStep = width * .18, upStep = width * .42;
    if (maxHeight != null && cards.length > 1) {
      final downs = cards.where((c) => !c.up).length;
      final ups = cards.length - downs - 1;
      final need = h + downs * downStep + ups * upStep;
      if (need > maxHeight!) {
        final scale = (maxHeight! - h) / (need - h);
        downStep *= scale;
        upStep *= scale;
      }
    }
    final tops = <double>[];
    var y = 0.0;
    for (var i = 0; i < cards.length; i++) {
      tops.add(y);
      y += cards[i].up ? upStep : downStep;
    }
    final total = cards.isEmpty ? h : tops.last + h;
    return GestureDetector(
      onTap: cards.isEmpty ? onTapEmpty : null,
      child: SizedBox(
        width: width,
        height: maxHeight ?? total,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: width,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * .12),
              border: Border.all(
                  color: highlight ? colors.primary : Colors.white24,
                  width: highlight ? 2.5 : 1.5),
            ),
          ),
          for (var i = 0; i < cards.length; i++)
            Positioned(
              top: tops[i],
              child: CardView(
                card: cards[i].card,
                faceDown: !cards[i].up,
                width: width,
                selected: selectedFrom != null && i >= selectedFrom!,
                onTap: onTapCard == null ? null : () => onTapCard!(i),
              ),
            ),
        ]),
      ),
    );
  }
}

/// A single pile showing only its top card (stock, waste, foundation, cell).
class PileSlot extends StatelessWidget {
  const PileSlot({
    super.key,
    required this.top,
    required this.width,
    this.faceDown = false,
    this.selected = false,
    this.label,
    this.onTap,
    this.count,
  });

  final PlayingCard? top;
  final double width;
  final bool faceDown;
  final bool selected;
  final String? label;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.4;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          if (top == null && !faceDown)
            Container(
              width: width,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * .12),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(label ?? '',
                  style: TextStyle(color: Colors.white54, fontSize: width * .32)),
            )
          else
            CardView(
                card: top, faceDown: faceDown, width: width, selected: selected, onTap: onTap),
          if (count != null && count! > 0)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Green felt background used by every solitaire.
class Felt extends StatelessWidget {
  const Felt({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E6B45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

/// Width for [n] side-by-side columns inside [available] pixels.
double columnWidth(double available, int n, {double gap = 4, double maxW = 72}) =>
    ((available - gap * (n - 1)) / n).clamp(20, maxW);
