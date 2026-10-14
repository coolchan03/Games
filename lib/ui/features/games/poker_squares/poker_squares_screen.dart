import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import '../common/poker_eval.dart';

/// American scoring for Poker Squares.
const pokerSquaresPoints = {
  HandCategory.straightFlush: 75,
  HandCategory.fourOfAKind: 50,
  HandCategory.straight: 15,
  HandCategory.fullHouse: 25,
  HandCategory.threeOfAKind: 10,
  HandCategory.flush: 20,
  HandCategory.twoPair: 5,
  HandCategory.pair: 2,
  HandCategory.highCard: 0,
};

int scoreLine(List<PlayingCard?> line) {
  if (line.any((c) => c == null)) return 0;
  final r = rankFive(line.cast<PlayingCard>());
  if (r.category == HandCategory.straightFlush && r.kickers.first == 14) return 100;
  return pokerSquaresPoints[r.category]!;
}

class PokerSquaresGame {
  PokerSquaresGame({Random? random}) {
    deck = standardDeckCards()..shuffle(random ?? Random());
  }
  late List<PlayingCard> deck;
  final grid = List<PlayingCard?>.filled(25, null);
  int placed = 0;

  PlayingCard? get next => placed < 25 ? deck[placed] : null;
  bool get over => placed == 25;

  bool place(int i) {
    if (over || grid[i] != null) return false;
    grid[i] = deck[placed++];
    return true;
  }

  List<int> get rowScores => [for (var r = 0; r < 5; r++) scoreLine(grid.sublist(r * 5, r * 5 + 5))];
  List<int> get colScores => [for (var c = 0; c < 5; c++) scoreLine([for (var r = 0; r < 5; r++) grid[r * 5 + c]])];
  int get total => rowScores.fold(0, (a, b) => a + b) + colScores.fold(0, (a, b) => a + b);
}

class PokerSquaresScreen extends StatefulWidget {
  const PokerSquaresScreen({super.key});
  @override
  State<PokerSquaresScreen> createState() => _PokerSquaresScreenState();
}

class _PokerSquaresScreenState extends State<PokerSquaresScreen> {
  PokerSquaresGame game = PokerSquaresGame();
  int best = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = game.rowScores, cols = game.colScores;
    if (game.over && game.total > best) best = game.total;
    return GameScaffold(
      gameId: 'poker_squares',
      completed: game.over && game.total >= 70,
      title: 'Poker Squares',
      onNewGame: () => setState(() => game = PokerSquaresGame()),
      rules: 'Place 25 cards, one at a time, anywhere in the 5×5 grid. Once '
          'placed, a card cannot move. Each of the five rows and five '
          'columns scores as a poker hand: royal flush 100, straight flush '
          '75, four of a kind 50, full house 25, flush 20, straight 15, '
          'three of a kind 10, two pair 5, pair 2. A score of 70 or more '
          'counts as a win.',
      children: [
        StatusBanner(
          game.over ? 'Final score ${game.total}${game.total >= 70 ? ' — great grid!' : ''}' : 'Score ${game.total} · card ${game.placed + 1} of 25',
          highlight: game.over,
        ),
        if (best > 0) Text('Best this session: $best', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (!game.over)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Next card: '),
            CardView(card: game.next, width: 56),
          ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 50) / 5.4;
          return Column(children: [
            for (var r = 0; r < 5; r++)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var c = 0; c < 5; c++)
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: GestureDetector(
                      onTap: () => setState(() => game.place(r * 5 + c)),
                      child: game.grid[r * 5 + c] == null
                          ? Container(
                              width: w,
                              height: w * 1.4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(w * .12),
                                color: colors.surfaceContainerHighest,
                                border: Border.all(color: colors.outlineVariant),
                              ),
                            )
                          : CardView(card: game.grid[r * 5 + c], width: w),
                    ),
                  ),
                SizedBox(width: 40, child: Text('${rows[r]}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var c = 0; c < 5; c++)
                SizedBox(width: w + 4, child: Text('${cols[c]}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 40),
            ]),
          ]);
        }),
      ],
    );
  }
}
