import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as rules;
import 'chess_session.dart';

class ChessBoard extends StatelessWidget {
  final ChessSession game;
  final bool flipped, enabled;
  final String? selected;
  final ValueChanged<String> onChoose;
  const ChessBoard({super.key, required this.game, required this.flipped,
    required this.enabled, required this.selected, required this.onChoose});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final targets = selected == null ? <String>{} : game.legalMoves
      .where((move) => move['from'] == selected).map((move) => move['to'] as String).toSet();
    const glyphs = {'k': '\u265a', 'q': '\u265b', 'r': '\u265c', 'b': '\u265d', 'n': '\u265e', 'p': '\u265f'};
    const names = {'k': 'king', 'q': 'queen', 'r': 'rook', 'b': 'bishop', 'n': 'knight', 'p': 'pawn'};
    return LayoutBuilder(builder: (context, bounds) {
      final size = max(384.0, min(640.0, bounds.maxWidth));
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(
        width: size, height: size, child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(), itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          itemBuilder: (context, index) {
            final cell = flipped ? 63 - index : index;
            final square = '${'abcdefgh'[cell % 8]}${8 - cell ~/ 8}';
            final piece = game.position.get(square);
            final white = piece?.color == rules.Color.WHITE;
            final kind = piece?.type.name;
            final target = targets.contains(square);
            final label = '$square, ${piece == null ? 'empty' : '${white ? 'white' : 'black'} ${names[kind]}'}${target ? ', legal destination' : ''}';
            return Semantics(label: label, button: true, selected: selected == square,
              excludeSemantics: true, child: Tooltip(message: label, child: InkWell(
                onTap: enabled ? () => onChoose(square) : null,
                child: Container(decoration: BoxDecoration(
                  color: selected == square ? colors.primaryContainer
                    : target ? colors.tertiaryContainer
                    : ((cell ~/ 8 + cell % 8).isEven ? colors.surfaceContainerLow : colors.surfaceContainerHighest),
                  border: Border.all(color: selected == square || target ? colors.primary : colors.outlineVariant,
                    width: selected == square || target ? 2 : 0.5)),
                  child: Stack(children: [
                    Positioned(left: 2, top: 1, child: Text(square, style: const TextStyle(fontSize: 9))),
                    Center(child: piece == null
                      ? (target ? const Icon(Icons.circle, size: 12) : const SizedBox.shrink())
                      : Text(glyphs[kind]!, style: TextStyle(fontSize: size / 12, height: 1,
                        color: white ? Colors.white : Colors.black,
                        shadows: const [Shadow(color: Colors.grey, blurRadius: 2, offset: Offset(1, 1))]))),
                    if (piece != null) Positioned(right: 2, bottom: 0, child: Text(white ? 'W' : 'B',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ])),
              )));
          })));
    });
  }
}
