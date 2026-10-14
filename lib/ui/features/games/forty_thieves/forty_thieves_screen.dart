import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'forty_thieves_engine.dart';

class FortyThievesScreen extends StatefulWidget {
  const FortyThievesScreen({super.key});
  @override
  State<FortyThievesScreen> createState() => _FortyThievesScreenState();
}

class _FortyThievesScreenState extends State<FortyThievesScreen> {
  FortyThievesGame game = FortyThievesGame();
  int? selected; // -1 waste, 0..9 column

  void _tapSource(int s) {
    setState(() {
      if (selected != null && selected != s && s >= 0 && game.moveTo(selected!, s)) {
        selected = null;
        return;
      }
      if (selected == s) {
        selected = null;
      } else if (!game.autoMove(s)) {
        selected = s;
      } else {
        selected = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onFoundations = game.foundations.fold(0, (s, f) => s + f.length);
    return GameScaffold(
      gameId: 'forty_thieves',
      completed: game.won,
      title: 'Forty Thieves',
      maxWidth: 820,
      onNewGame: () => setState(() {
        game = FortyThievesGame();
        selected = null;
      }),
      rules: 'Two decks. Build eight foundations up by suit from Ace to King. '
          'The ten columns build down in the same suit, and only the top '
          'card of a column can move — one card at a time. Any card may go '
          'into an empty column. Turn the stock one card at a time onto the '
          'waste; there is no redeal. A hard patience: plan ahead!',
      children: [
        Row(children: [
          Expanded(child: StatusBanner(game.won ? 'Solved!' : '$onFoundations/104 on foundations · ${game.stock.length} in stock', highlight: game.won)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? () => setState(() {
              game.undo();
              selected = null;
            }) : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 10, gap: 3, maxW: 64);
          return Felt(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var f = 0; f < 8; f++)
                  PileSlot(top: game.foundations[f].isEmpty ? null : game.foundations[f].last, width: w, label: 'A'),
                PileSlot(top: game.waste.isEmpty ? null : game.waste.last, width: w, selected: selected == -1, onTap: () => _tapSource(-1)),
                PileSlot(
                  top: null,
                  faceDown: game.stock.isNotEmpty,
                  width: w,
                  count: game.stock.length,
                  onTap: () => setState(() {
                    selected = null;
                    game.draw();
                  }),
                ),
              ]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t = 0; t < 10; t++)
                    CardColumn(
                      cards: game.tableau[t],
                      width: w,
                      maxHeight: w * 8,
                      selectedFrom: selected == t ? game.tableau[t].length - 1 : null,
                      onTapCard: (i) => i == game.tableau[t].length - 1 ? _tapSource(t) : null,
                      onTapEmpty: () {
                        if (selected != null) {
                          setState(() {
                            game.moveTo(selected!, t);
                            selected = null;
                          });
                        }
                      },
                    ),
                ],
              ),
            ]),
          );
        }),
      ],
    );
  }
}
