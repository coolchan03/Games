import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';
import 'pyramid_engine.dart';

class PyramidScreen extends StatefulWidget {
  const PyramidScreen({super.key});
  @override
  State<PyramidScreen> createState() => _PyramidScreenState();
}

class _PyramidScreenState extends State<PyramidScreen> {
  PyramidGame game = PyramidGame();
  int? selected;

  void _tap(int src) {
    if (!game.isFree(src)) return;
    setState(() {
      if (selected == null) {
        if (!game.remove(src)) selected = src;
      } else if (selected == src) {
        selected = null;
      } else {
        if (!game.remove(selected!, src)) {
          selected = game.remove(src) ? null : src;
        } else {
          selected = null;
        }
      }
    });
  }

  Widget _pyramidCard(int index, double width) {
    final card = game.cardAt(index)!;
    final free = game.isFree(index);
    final face = CardView(
      card: card,
      width: width,
      dimmed: !free,
      selected: selected == index,
      onTap: () => _tap(index),
    );
    final source = free
        ? Draggable<Object>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: CardView(card: card, width: width, selected: true),
            ),
            childWhenDragging: Opacity(opacity: .35, child: face),
            child: face,
          )
        : face;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final from = details.data;
        return from is int && from != index && game.isFree(from) && free &&
            aceLow(game.cardAt(from)!) + aceLow(card) == 13;
      },
      onAcceptWithDetails: (details) => setState(() {
        if (game.remove(details.data as int, index)) selected = null;
      }),
      builder: (context, candidates, rejected) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: candidates.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = game.pyramid.where((c) => c != null).length;
    return GameScaffold(
      gameId: 'pyramid',
      deadEnd: game.stuck,
      onUndo: game.canUndo
          ? () => setState(() {
        game.undo();
        selected = null;
      })
          : null,
      completed: game.won,
      title: 'Pyramid',
      onNewGame: () => setState(() {
        game = PyramidGame();
        selected = null;
      }),
      rules: 'Remove the whole pyramid by pairing two uncovered cards that add '
          'up to 13 (Ace = 1, Jack = 11, Queen = 12). Kings are removed on '
          'their own. A card is uncovered when no card overlaps it from the '
          'row below. Turn cards from the stock and pair them too; the stock '
          'can be gone through three times.',
      children: [
        Row(children: [
          Expanded(
            child: StatusBanner(
              game.won
                  ? 'Pyramid cleared!'
                  : game.stuck
                      ? 'No more moves · $left cards left'
                      : '$left pyramid cards left · ${game.recycles} redeals',
              highlight: game.won,
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
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 7, gap: 2, maxW: cardMaxWidth(context, 64));
          final h = w * 1.4;
          return Felt(
            child: Column(children: [
              SizedBox(
                height: h + 6 * h * .5,
                width: 7 * (w + 2),
                child: Stack(children: [
                  for (var r = 0; r < 7; r++)
                    for (var c = 0; c <= r; c++)
                      if (game.pyramid[PyramidGame.indexOf(r, c)] != null)
                        Positioned(
                          top: r * h * .5,
                          left: (6 - r) * (w + 2) / 2 + c * (w + 2),
                          child: _pyramidCard(PyramidGame.indexOf(r, c), w),
                        ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                PileSlot(
                  top: null,
                  faceDown: game.stock.isNotEmpty,
                  label: game.recycles > 0 ? '↻' : '',
                  width: w * 1.2,
                  count: game.stock.length,
                  onTap: () => setState(() {
                    selected = null;
                    game.draw();
                  }),
                ),
                const SizedBox(width: 16),
                PileSlot(
                  top: game.waste.isEmpty ? null : game.waste.last,
                  width: w * 1.2,
                  selected: selected == -1,
                  dragData: game.waste.isEmpty ? null : -1,
                  canAccept: (source) => source is int &&
                      source >= 0 && game.isFree(source) &&
                      game.waste.isNotEmpty &&
                      aceLow(game.cardAt(source)!) +
                          aceLow(game.waste.last) == 13,
                  onAccept: (source) => setState(() {
                    if (game.remove(source as int, -1)) selected = null;
                  }),
                  onTap: () => _tap(-1),
                ),
              ]),
            ]),
          );
        }),
      ],
    );
  }
}
