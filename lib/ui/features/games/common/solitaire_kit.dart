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
    this.dragDataAt,
    this.canAccept,
    this.onAccept,
    this.maxHeight,
    this.highlight = false,
  });

  final List<SCard> cards;
  final double width;
  final int? selectedFrom;
  final void Function(int index)? onTapCard;
  final VoidCallback? onTapEmpty;
  /// Returns a draggable source for a face-up card or a movable suffix.
  final Object? Function(int index)? dragDataAt;
  final bool Function(Object source)? canAccept;
  final void Function(Object source)? onAccept;
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
    final column = GestureDetector(
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
              child: _dragCard(i),

            ),
        ]),
      ),
    );
    if (canAccept == null) return column;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) => canAccept!(details.data),
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
      builder: (context, candidate, rejected) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: candidate.isNotEmpty ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: column,
      ),
    );
  }

  Widget _dragCard(int i) {
    final card = cards[i];
    final face = CardView(
      card: card.card,
      faceDown: !card.up,
      width: width,
      selected: selectedFrom != null && i >= selectedFrom!,
      onTap: onTapCard == null ? null : () => onTapCard!(i),
    );
    final source = card.up ? dragDataAt?.call(i) : null;
    if (source == null) return face;
    final count = cards.length - i;
    return Draggable<Object>(
      data: source,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width,
          height: width * 1.4 + (count.clamp(1, 7) - 1) * width * .22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var offset = 0; offset < count.clamp(1, 7); offset++)
                Positioned(
                  top: offset * width * .22,
                  left: 0,
                  child: CardView(
                    card: cards[i + offset].card,
                    width: width,
                    selected: offset == 0,
                  ),
                ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: face),
      child: face,
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
    this.dragData,
    this.canAccept,
    this.onAccept,
  });

  final PlayingCard? top;
  final double width;
  final bool faceDown;
  final bool selected;
  final String? label;
  final VoidCallback? onTap;
  final int? count;
  final Object? dragData;
  final bool Function(Object source)? canAccept;
  final void Function(Object source)? onAccept;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.4;
    final slot = GestureDetector(
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
            _dragTop(),
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
    if (canAccept == null) return slot;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) => canAccept!(details.data),
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
      builder: (context, candidate, rejected) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: candidate.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: slot,
      ),
    );
  }

  Widget _dragTop() {
    final face = CardView(
      card: top, faceDown: faceDown, width: width,
      selected: selected, onTap: onTap,
    );
    if (top == null || faceDown || dragData == null) return face;
    return Draggable<Object>(
      data: dragData!,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: CardView(card: top, width: width, selected: true),
      ),
      childWhenDragging: Opacity(opacity: .35, child: face),
      child: face,
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
/// Largest card width for a layout: [phone] on a portrait phone, larger in
/// landscape and much larger on tablets and desktops, so cards fill the
/// table instead of looking zoomed out.
double cardMaxWidth(BuildContext context, double phone) {
  final size = MediaQuery.sizeOf(context);
  if (size.shortestSide >= 600 || size.width >= 900) return phone * 1.9;
  if (size.width > size.height) return phone * 1.35;
  return phone;
}

double columnWidth(double available, int n, {double gap = 4, double maxW = 72}) =>
    ((available - gap * (n - 1)) / n).clamp(20, maxW);
