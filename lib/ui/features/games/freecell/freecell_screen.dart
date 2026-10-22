import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'freecell_engine.dart';

class FreeCellScreen extends StatefulWidget {
  const FreeCellScreen({super.key});
  @override
  State<FreeCellScreen> createState() => _FreeCellScreenState();
}

class _FreeCellScreenState extends State<FreeCellScreen> {
  final rng = Random();
  late FreeCellGame game;
  FRef? selected;

  @override
  void initState() {
    super.initState();
    _deal(rng.nextInt(32000) + 1);
  }

  void _deal(int n) {
    game = FreeCellGame(n);
    selected = null;
    game.autoPlay();
  }

  void _after() {
    selected = null;
    game.autoPlay();
  }

  void _tapSource(FRef ref) {
    setState(() {
      if (selected != null && selected != ref) {
        final to = ref.pile == FPile.tableau ? FRef(FPile.tableau, ref.index) : ref;
        if (game.move(selected!, to)) {
          _after();
          return;
        }
      }
      if (selected == ref) {
        selected = null;
        return;
      }
      final auto = game.autoTarget(ref);
      if (auto != null) {
        game.move(ref, auto);
        _after();
      } else {
        selected = ref;
      }
    });
  }

  void _drop(FRef from, FRef to) {
    setState(() {
      if (game.move(from, to)) _after();
    });
  }

  void _tapTarget(FRef to) {
    if (selected == null) return;
    setState(() {
      if (game.move(selected!, to)) {
        _after();
      } else {
        selected = null;
      }
    });
  }

  Future<void> _chooseNumber() async {
    final ctrl = TextEditingController(text: '${game.number}');
    final n = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deal number (1–32000)'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Deal'),
          ),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= 32000) setState(() => _deal(n));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactLandscape = size.width > size.height && size.height < 650;
    return GameScaffold(
      gameId: 'freecell',
      completed: game.won,
      title: 'FreeCell',
      maxWidth: compactLandscape ? 1060 : 760,
      onNewGame: () => setState(() => _deal(rng.nextInt(32000) + 1)),
      rules: 'All 52 cards are dealt face up into eight columns. Build the '
          'four foundations up by suit from Ace to King. Columns build down '
          'in alternating colours. The four free cells each hold one card.\n\n'
          'You can move a run of cards at once if there is enough free space: '
          '(free cells + 1) × 2 for each empty column. Deals are numbered '
          'like the classic Windows game — nearly all are solvable. '
          'Drag cards or valid descending stacks onto an eligible destination.',
      children: [
        Row(children: [
          Expanded(
            child: StatusBanner(
              game.won
                  ? 'Solved deal #${game.number} in ${game.moves} moves!'
                  : game.noMovesLeft
                      ? 'No moves left - undo or choose a new deal'
                      : 'Deal #${game.number}, Moves ${game.moves}',
              highlight: game.won || game.noMovesLeft,
            ),
          ),
          IconButton(tooltip: 'Choose deal', onPressed: _chooseNumber, icon: const Icon(Icons.tag)),
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
          final w = columnWidth(box.maxWidth - 16, 8, maxW: compactLandscape ? 90 : 72);
          return Felt(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var c = 0; c < 4; c++)
                  PileSlot(
                    top: game.cells[c]?.card,
                    width: w,
                    selected: selected == FRef(FPile.cell, c),
                    dragData: game.cells[c] != null ? FRef(FPile.cell, c) : null,
                    canAccept: (source) => source is FRef &&
                        game.canMove(source, FRef(FPile.cell, c)),
                    onAccept: (source) => _drop(source as FRef, FRef(FPile.cell, c)),
                    onTap: () => game.cells[c] == null
                        ? _tapTarget(FRef(FPile.cell, c))
                        : _tapSource(FRef(FPile.cell, c)),
                  ),
                for (var f = 0; f < 4; f++)
                  PileSlot(
                    top: game.foundations[f].isEmpty ? null : game.foundations[f].last.card,
                    width: w,
                    label: 'A',
                    dragData: game.foundations[f].isNotEmpty
                        ? FRef(FPile.foundation, f) : null,
                    canAccept: (source) => source is FRef &&
                        game.canMove(source, FRef(FPile.foundation, f)),
                    onAccept: (source) =>
                        _drop(source as FRef, FRef(FPile.foundation, f)),
                    onTap: () => selected != null
                        ? _tapTarget(FRef(FPile.foundation, f))
                        : game.foundations[f].isNotEmpty
                            ? _tapSource(FRef(FPile.foundation, f))
                            : null,
                  ),
              ]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t = 0; t < 8; t++)
                    CardColumn(
                      cards: game.tableau[t],
                      width: w,
                      maxHeight: compactLandscape
                          ? (size.height * .58).clamp(w * 2.2, w * 5)
                          : w * 7.5,
                      dragDataAt: (i) => FRef(FPile.tableau, t, i),
                      canAccept: (source) => source is FRef &&
                          game.canMove(source, FRef(FPile.tableau, t)),
                      onAccept: (source) =>
                          _drop(source as FRef, FRef(FPile.tableau, t)),
                      selectedFrom: selected?.pile == FPile.tableau && selected?.index == t
                          ? selected!.card
                          : null,
                      onTapCard: (i) => _tapSource(FRef(FPile.tableau, t, i)),
                      onTapEmpty: () => _tapTarget(FRef(FPile.tableau, t)),
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
