import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'klondike_engine.dart';

class KlondikeScreen extends StatefulWidget {
  const KlondikeScreen({super.key});
  @override
  State<KlondikeScreen> createState() => _KlondikeScreenState();
}

class _KlondikeScreenState extends State<KlondikeScreen> {
  bool drawThree = false;
  late KlondikeGame game;
  KRef? selected;

  @override
  void initState() {
    super.initState();
    game = KlondikeGame(drawThree: drawThree);
  }

  void _newGame() => setState(() {
        game = KlondikeGame(drawThree: drawThree);
        selected = null;
      });

  void _tapSource(KRef ref) {
    setState(() {
      if (selected != null) {
        if (selected == ref) {
          selected = null;
          return;
        }
        // Tapping another pile while holding a selection tries to move there.
        final target = ref.pile == KPile.tableau ? KRef(KPile.tableau, ref.index) : ref;
        if (game.move(selected!, target)) {
          selected = null;
          return;
        }
      }
      final auto = game.autoTarget(ref);
      if (auto != null) {
        game.move(ref, auto);
        selected = null;
      } else {
        selected = ref;
      }
    });
  }

  void _tapTarget(KRef to) {
    if (selected == null) return;
    setState(() {
      game.move(selected!, to);
      selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      gameId: 'klondike',
      completed: game.won,
      title: 'Klondike',
      onNewGame: _newGame,
      maxWidth: 720,
      rules: 'Build four foundations up by suit from Ace to King. In the seven '
          'columns, build down in alternating colours (red on black). Any '
          'face-up run can move as a unit, and only a King may fill an empty '
          'column. Tap the stock to turn cards over; when it runs out, tap '
          'again to recycle the waste.\n\nTap a card to send it to the best '
          'spot automatically. If there is none it is selected — then tap '
          'where it should go.',
      children: [
        Row(children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Draw 1')),
                ButtonSegment(value: true, label: Text('Draw 3')),
              ],
              selected: {drawThree},
              onSelectionChanged: (s) {
                drawThree = s.first;
                _newGame();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? () => setState(game.undo) : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        StatusBanner(
          game.won ? 'You won in ${game.moves} moves!' : 'Moves: ${game.moves}',
          highlight: game.won,
        ),
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 7);
          return Felt(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                PileSlot(
                  top: null,
                  faceDown: game.stock.isNotEmpty,
                  width: w,
                  label: '↻',
                  count: game.stock.length,
                  onTap: () => setState(() {
                    selected = null;
                    game.drawStock();
                  }),
                ),
                SizedBox(
                  width: w * 2 + 4,
                  height: w * 1.4,
                  child: Stack(children: [
                    for (var k = 0; k < (game.drawThree ? 3 : 1); k++)
                      if (game.waste.length > k)
                        Positioned(
                          left: (game.drawThree
                                  ? (min3(game.waste.length) - 1 - k)
                                  : 0) *
                              w *
                              .35,
                          child: CardView(
                            card: game.waste[game.waste.length - 1 - k].card,
                            width: w,
                            selected: k == 0 && selected?.pile == KPile.waste,
                            onTap: k == 0 ? () => _tapSource(const KRef(KPile.waste)) : null,
                          ),
                        ),
                  ].reversed.toList()),
                ),
                for (var f = 0; f < 4; f++)
                  PileSlot(
                    top: game.foundations[f].isEmpty ? null : game.foundations[f].last.card,
                    width: w,
                    label: 'A',
                    selected: selected == KRef(KPile.foundation, f),
                    onTap: () => selected != null
                        ? _tapTarget(KRef(KPile.foundation, f))
                        : game.foundations[f].isEmpty
                            ? null
                            : _tapSource(KRef(KPile.foundation, f)),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t = 0; t < 7; t++)
                    CardColumn(
                      cards: game.tableau[t],
                      width: w,
                      maxHeight: w * 7,
                      selectedFrom: selected?.pile == KPile.tableau && selected?.index == t
                          ? selected!.card
                          : null,
                      onTapCard: (i) => game.tableau[t][i].up
                          ? _tapSource(KRef(KPile.tableau, t, i))
                          : null,
                      onTapEmpty: () => _tapTarget(KRef(KPile.tableau, t)),
                    ),
                ],
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        if (game.canAutoFinish && !game.won)
          FilledButton.icon(
            onPressed: () => setState(game.autoFinish),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Finish automatically'),
          ),
      ],
    );
  }

  static int min3(int n) => n < 3 ? n : 3;
}
