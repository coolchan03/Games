import 'package:flutter/material.dart';

import 'cards/card.dart';

/// Vector playing card shared by every card game (no image assets).
class CardView extends StatelessWidget {
  const CardView({
    super.key,
    this.card,
    this.faceDown = false,
    this.width = 56,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
  });

  final PlayingCard? card;
  final bool faceDown;
  final double width;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  static Color suitColor(Suit s) => s == Suit.hearts || s == Suit.diamonds
      ? const Color(0xFFC62828)
      : const Color(0xFF1B1B1F);

  static String rankLabel(Rank r) => r == Rank.ten ? '10' : r.asciiChar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = width * 1.4;
    final c = card;
    Widget face;
    if (c == null && !faceDown) {
      face = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * .12),
          border: Border.all(color: colors.outlineVariant, width: 1.5),
        ),
      );
    } else if (faceDown || c == null) {
      face = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * .12),
          border: Border.all(color: Colors.white, width: 2),
          gradient: LinearGradient(
            colors: [colors.primary, colors.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
                blurRadius: 2, offset: Offset(0, 1), color: Colors.black26)
          ],
        ),
        child: Center(
          child: Icon(Icons.style_rounded,
              color: Colors.white70, size: width * .45),
        ),
      );
    } else {
      final ink = suitColor(c.suit);
      face = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * .12),
          border: Border.all(
              color: selected ? colors.primary : Colors.black26,
              width: selected ? 3 : 1),
          boxShadow: const [
            BoxShadow(
                blurRadius: 2, offset: Offset(0, 1), color: Colors.black26)
          ],
        ),
        child: Stack(children: [
          Positioned(
            left: width * .08,
            top: width * .04,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(rankLabel(c.rank),
                  style: TextStyle(
                      color: ink,
                      fontSize: width * .3,
                      height: 1,
                      fontWeight: FontWeight.w700)),
              Text(c.suit.symbolChar,
                  style:
                      TextStyle(color: ink, fontSize: width * .26, height: 1)),
            ]),
          ),
          Align(
            alignment: const Alignment(.35, .45),
            child: Text(c.suit.symbolChar,
                style: TextStyle(color: ink, fontSize: width * .55)),
          ),
        ]),
      );
    }
    final label = c == null || faceDown
        ? 'Face-down card'
        : '${rankLabel(c.rank)} of ${c.suit.name}';
    return Semantics(
      label: label,
      button: onTap != null,
      selected: selected,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        offset: selected ? const Offset(0, -.12) : Offset.zero,
        child: Opacity(
          opacity: dimmed ? .45 : 1,
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(width: width, height: height, child: face),
          ),
        ),
      ),
    );
  }
}

/// A hand of cards laid out with overlap so 13 cards fit a phone screen.
class HandView extends StatelessWidget {
  const HandView({
    super.key,
    required this.cards,
    this.playable,
    this.selected = const {},
    this.onTap,
    this.cardWidth = 56,
    this.faceDown = false,
  });

  final List<PlayingCard> cards;

  /// Show only card backs (an opponent's hidden hand).
  final bool faceDown;
  final Set<PlayingCard>? playable;
  final Set<PlayingCard> selected;
  final void Function(PlayingCard)? onTap;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (cards.isEmpty) return SizedBox(height: cardWidth * 1.5);
      final available = box.maxWidth;
      final step = cards.length == 1
          ? cardWidth
          : ((available - cardWidth) / (cards.length - 1))
              .clamp(cardWidth * .28, cardWidth + 4);
      final total = step * (cards.length - 1) + cardWidth;
      return SizedBox(
        height: cardWidth * 1.4 + cardWidth * .2,
        child: Center(
          child: SizedBox(
            width: total,
            child: Stack(clipBehavior: Clip.none, children: [
              for (var i = 0; i < cards.length; i++)
                Positioned(
                  left: i * step,
                  top: cardWidth * .2,
                  child: CardView(
                    card: cards[i],
                    faceDown: faceDown,
                    width: cardWidth,
                    selected: selected.contains(cards[i]),
                    dimmed: playable != null && !playable!.contains(cards[i]),
                    onTap: onTap == null ? null : () => onTap!(cards[i]),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }
}

/// Sort helper: group by suit (♠ ♥ ♣ ♦ alternating colours), high to low.
List<PlayingCard> sortedForDisplay(Iterable<PlayingCard> cards) {
  const order = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];
  final list = cards.toList();
  list.sort((a, b) {
    final s = order.indexOf(a.suit) - order.indexOf(b.suit);
    return s != 0 ? s : b.rank.index - a.rank.index;
  });
  return list;
}
