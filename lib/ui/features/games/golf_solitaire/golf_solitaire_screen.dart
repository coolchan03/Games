import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'golf_engine.dart';

class GolfSolitaireScreen extends StatefulWidget {
  const GolfSolitaireScreen({super.key});
  @override
  State<GolfSolitaireScreen> createState() => _GolfSolitaireScreenState();
}

class _GolfSolitaireScreenState extends State<GolfSolitaireScreen> {
  GolfGame game = GolfGame();

  @override
  Widget build(BuildContext context) {
    final status = game.won
        ? 'Hole in one — all cleared!'
        : game.stuck
            ? 'No moves left · ${game.remaining} cards remain (your score)'
            : '${game.remaining} cards left · ${game.stock.length} in stock';
    return GameScaffold(
      gameId: 'golf_solitaire',
      completed: game.won,
      title: 'Golf',
      onNewGame: () => setState(() => game = GolfGame()),
      rules: 'Clear the seven columns onto the waste pile. Tap the bottom card '
          'of a column if it is one rank higher or lower than the waste card '
          '(suits do not matter, Aces are low, and nothing can be played on a '
          'King). Tap the stock when stuck. Like golf, a lower score — cards '
          'left over — is better.',
      children: [
        Row(children: [
          Expanded(child: StatusBanner(status, highlight: game.won)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? () => setState(game.undo) : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 7);
          return Felt(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < 7; c++)
                    CardColumn(
                      cards: [for (final card in game.columns[c]) SCard(card, up: true)],
                      width: w,
                      highlight: game.canPlay(c),
                      dragDataAt: (index) =>
                          index == game.columns[c].length - 1 && game.canPlay(c)
                              ? c : null,
                      onTapCard: (_) => setState(() => game.play(c)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                PileSlot(
                  top: null,
                  faceDown: game.stock.isNotEmpty,
                  width: w * 1.3,
                  count: game.stock.length,
                  onTap: () => setState(game.draw),
                ),
                const SizedBox(width: 16),
                PileSlot(
                  top: game.waste.last,
                  width: w * 1.3,
                  canAccept: (source) => source is int &&
                      source >= 0 && source < game.columns.length &&
                      game.canPlay(source),
                  onAccept: (source) =>
                      setState(() => game.play(source as int)),
                ),
              ]),
            ]),
          );
        }),
      ],
    );
  }
}
