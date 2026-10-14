import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'spider_engine.dart';

class SpiderScreen extends StatefulWidget {
  const SpiderScreen({super.key});
  @override
  State<SpiderScreen> createState() => _SpiderScreenState();
}

class _SpiderScreenState extends State<SpiderScreen> {
  int suits = 1;
  late SpiderGame game = SpiderGame(suits: suits);
  (int, int)? selected;
  String? note;

  void _tap(int col, int index) {
    setState(() {
      note = null;
      if (selected != null && selected!.$1 != col) {
        if (game.move(selected!.$1, selected!.$2, col)) {
          selected = null;
          return;
        }
      }
      if (selected == (col, index)) {
        selected = null;
        return;
      }
      if (index < game.runStart(col)) {
        selected = null;
        return;
      }
      final to = game.autoTarget(col, index);
      if (to != null) {
        game.move(col, index, to);
        selected = null;
      } else {
        selected = (col, index);
      }
    });
  }

  void _tapEmpty(int col) {
    if (selected == null) return;
    setState(() {
      game.move(selected!.$1, selected!.$2, col);
      selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Spider',
      maxWidth: 820,
      onNewGame: () => setState(() {
        game = SpiderGame(suits: suits);
        selected = null;
      }),
      rules: 'Two decks in ten columns. Build down regardless of suit, but '
          'only runs of the same suit move together. Complete a King-to-Ace '
          'run in one suit to clear it; clear all eight to win.\n\nTap the '
          'stock to deal one card onto every column (all columns must have '
          'at least one card). Choose 1, 2 or 4 suits for difficulty.',
      children: [
        Row(children: [
          Expanded(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 suit')),
                ButtonSegment(value: 2, label: Text('2 suits')),
                ButtonSegment(value: 4, label: Text('4 suits')),
              ],
              selected: {suits},
              onSelectionChanged: (s) => setState(() {
                suits = s.first;
                game = SpiderGame(suits: suits);
                selected = null;
              }),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? () => setState(() {
              game.undo();
              selected = null;
            }) : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        StatusBanner(
          game.won
              ? 'You won! Score ${game.score}'
              : note ?? 'Runs ${game.completed}/8 · Score ${game.score} · Moves ${game.moves}',
          highlight: game.won,
        ),
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 10, gap: 3, maxW: 64);
          return Felt(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t = 0; t < 10; t++)
                    CardColumn(
                      cards: game.tableau[t],
                      width: w,
                      maxHeight: w * 9,
                      selectedFrom: selected?.$1 == t ? selected!.$2 : null,
                      onTapCard: (i) => _tap(t, i),
                      onTapEmpty: () => _tapEmpty(t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                PileSlot(
                  top: null,
                  faceDown: game.stock.isNotEmpty,
                  width: w * 1.2,
                  count: game.dealsLeft,
                  onTap: () => setState(() {
                    selected = null;
                    if (!game.deal() && game.stock.isNotEmpty) {
                      note = 'Fill every empty column before dealing.';
                    }
                  }),
                ),
              ]),
            ]),
          );
        }),
      ],
    );
  }
}
