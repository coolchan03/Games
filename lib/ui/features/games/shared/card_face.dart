import 'package:flutter/material.dart';
import 'playing_cards.dart';

class CardFace extends StatelessWidget {
  final PlayingCard? card;
  final bool hidden, selected, showTooltip;
  final VoidCallback? onTap;
  const CardFace({super.key, this.card, this.hidden = false,
    this.selected = false, this.showTooltip = true, this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = hidden || card == null ? 'Hidden card' : card!.semanticLabel;
    return Semantics(label: label, button: onTap != null, selected: selected,
      excludeSemantics: true, child: Tooltip(message: label,
        triggerMode: showTooltip ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
        child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Container(width: 62, height: 92, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceContainerHigh,
            border: Border.all(color: selected ? colors.primary : colors.outline,
              width: selected ? 3 : 1), borderRadius: BorderRadius.circular(10)),
          child: Text(hidden || card == null ? '?' : card!.label,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimaryContainer : colors.onSurface)),
        ),
      )));
  }
}
