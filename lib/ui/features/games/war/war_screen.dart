import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';

/// War: flip the top cards; the higher card takes both. Ties start a "war":
/// three cards face down, then another face up decides the whole pile.
class WarGame {
  WarGame({Random? random}) : rng = random ?? Random() {
    final deck = standardDeckCards()..shuffle(rng);
    hands = [deck.sublist(0, 26), deck.sublist(26)];
  }
  final Random rng;
  late List<List<PlayingCard>> hands;
  List<PlayingCard> table = [];
  (PlayingCard, PlayingCard)? lastFlip;
  String log = '';
  int rounds = 0;

  int? get winner => hands[0].isEmpty ? 1 : hands[1].isEmpty ? 0 : null;

  static int v(PlayingCard c) => c.rank.numericValue;

  void flip() {
    if (winner != null) return;
    rounds++;
    table = [];
    while (true) {
      if (hands[0].isEmpty || hands[1].isEmpty) return;
      final a = hands[0].removeAt(0), b = hands[1].removeAt(0);
      table.addAll([a, b]);
      lastFlip = (a, b);
      if (v(a) != v(b)) {
        final w = v(a) > v(b) ? 0 : 1;
        table.shuffle(rng);
        hands[w].addAll(table);
        log = '${w == 0 ? 'You take' : 'Computer takes'} ${table.length} cards';
        return;
      }
      log = 'War!';
      for (var k = 0; k < 3; k++) {
        if (hands[0].length > 1) table.add(hands[0].removeAt(0));
        if (hands[1].length > 1) table.add(hands[1].removeAt(0));
      }
    }
  }
}

class WarScreen extends StatefulWidget {
  const WarScreen({super.key});
  @override
  State<WarScreen> createState() => _WarScreenState();
}

class _WarScreenState extends State<WarScreen> {
  WarGame game = WarGame();

  @override
  Widget build(BuildContext context) {
    final w = game.winner;
    return GameScaffold(
      gameId: 'war',
      completed: w == 0,
      title: 'War',
      onNewGame: () => setState(() => game = WarGame()),
      rules: 'The deck is split between you and the computer. Both flip the '
          'top card; the higher card wins both. On a tie it\'s war: each puts '
          'three cards face down and one face up, and the higher face-up card '
          'takes the whole pile. Win by collecting all 52 cards.',
      children: [
        StatusBanner(
          w == null ? (game.log.isEmpty ? 'Tap Flip to play' : game.log) : (w == 0 ? 'You won all the cards!' : 'The computer won all the cards'),
          highlight: w != null,
        ),
        Text('Computer: ${game.hands[1].length} cards', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CardView(card: game.lastFlip?.$1, width: 90),
          const SizedBox(width: 24),
          CardView(card: game.lastFlip?.$2, width: 90),
        ]),
        const SizedBox(height: 10),
        Text('You: ${game.hands[0].length} cards · round ${game.rounds}', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: w == null ? () => setState(game.flip) : null, child: const Text('Flip'))),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: w == null
                  ? () => setState(() {
                        for (var i = 0; i < 25 && game.winner == null; i++) {
                          game.flip();
                        }
                      })
                  : null,
              child: const Text('Fast-forward 25'),
            ),
          ),
        ]),
      ],
    );
  }
}
