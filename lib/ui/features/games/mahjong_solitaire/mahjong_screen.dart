import 'package:flutter/material.dart';
import 'engine/mahjong_board.dart';

class MahjongSolitaireScreen extends StatefulWidget {
  const MahjongSolitaireScreen({super.key});
  @override
  State<MahjongSolitaireScreen> createState() => _MahjongSolitaireState();
}
class _MahjongSolitaireState extends State<MahjongSolitaireScreen> {
  MahjongBoard game = MahjongBoard.generate();
  int? selected;
  MahjongPair? highlighted;
  int pairsRemoved = 0;

  void newGame() => setState(() {
    game = MahjongBoard.generate();
    selected = null;
    highlighted = null;
    pairsRemoved = 0;
  });
  void choose(int index) {
    if (!game.isFree(index)) return;
    if (selected == null || selected == index) {
      setState(() => selected = selected == index ? null : index);
      return;
    }
    setState(() {
      if (game.remove(selected!, index)) pairsRemoved++;
      selected = null;
      highlighted = null;
    });
  }
  void hint() {
    if (game.matches.isEmpty) return;
    setState(() => highlighted = game.matches.first);
  }
  void undo() {
    if (game.history.isEmpty) return;
    setState(() {
      game.undo();
      pairsRemoved--;
      selected = null;
      highlighted = null;
    });
  }

  Widget tile(int index, ColorScheme colors) {
    final face = game.tiles[index];
    if (face == null) return const SizedBox.expand();
    final free = game.isFree(index);
    final isSelected = selected == index;
    final isHinted = highlighted?.first == index ||
        highlighted?.second == index;
    return InkWell(
      onTap: () => choose(index),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer
              : isHinted ? colors.tertiaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: isSelected || isHinted ? 2.0 : 1.0,
            color: isSelected || isHinted ? colors.primary
                : colors.outlineVariant,
          ),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(fit: BoxFit.scaleDown,
            child: Text(MahjongBoard.tileGlyph(face),
              style: const TextStyle(fontSize: 28))),
          if (!free)
            Icon(Icons.lock_outline,
              color: colors.onSurfaceVariant, size: 11),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final won = game.complete;
    final stuck = !won && game.matches.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Mahjong Solitaire')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Compact, single-layer Mahjong. Match identical free '
            'tiles. A tile is free if its left or right side is open. '
            'Each new board is generated from a valid solution.',
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(won ? 'Cleared the board!' : stuck ? 'No moves: undo or restart'
              : '${game.remaining} tiles left · $pairsRemoved pairs matched',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          AspectRatio(aspectRatio: 1,
            child: GridView.builder(
              itemCount: 64,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8),
              itemBuilder: (context, index) => tile(index, colors),
            )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: newGame,
              icon: const Icon(Icons.restart_alt),
              label: const Text('New game'),
            )),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Undo pair',
              onPressed: game.history.isNotEmpty ? undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton.filledTonal(
              tooltip: 'Show available pair',
              onPressed: game.matches.isNotEmpty ? hint : null,
              icon: const Icon(Icons.lightbulb_outline),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('This is the lightweight flat-layout variant. '
            'Traditional layered turtle layouts are planned separately.',
            textAlign: TextAlign.center),
        ]),
      ))),
    );
  }
}
