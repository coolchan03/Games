import 'package:flutter/material.dart';
import 'card_face.dart';
import 'playing_cards.dart';

/// Tap a card or deliberately hold-and-drag it; scroll is left intact
/// until the long-press threshold. Drop targets decide legality.
class TouchCard<T extends Object> extends StatelessWidget {
  const TouchCard({
    super.key,
    required this.card,
    required this.data,
    this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final PlayingCard card;
  final T data;
  final VoidCallback? onTap;
  final bool selected, enabled;

  @override
  Widget build(BuildContext context) {
    Widget face({bool faint = false}) => Opacity(
      opacity: faint ? 0.32 : 1,
      child: CardFace(
        card: card, selected: selected, onTap: faint ? null : onTap,
        showTooltip: false,
      ),
    );

    return LongPressDraggable<T>(
      data: data,
      maxSimultaneousDrags: enabled ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: face(),
      ),
      childWhenDragging: face(faint: true),
      child: face(),
    );
  }
}

/// Legal drag targets highlight on hover; rejected or cancelled drops
/// never invoke the game engine. Tap selection remains a full alternative.
class CardDropZone<T extends Object> extends StatelessWidget {
  const CardDropZone({
    super.key,
    required this.canAccept,
    required this.onAccept,
    required this.child,
  });

  final bool Function(T) canAccept;
  final ValueChanged<T> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, accepted, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accepted.isEmpty ? colors.outlineVariant : colors.primary,
            width: accepted.isEmpty ? 1 : 3,
          ),
          color: accepted.isEmpty ? colors.surfaceContainerLow : colors.primaryContainer,
        ),
        child: child,
      ),
    );
  }
}
