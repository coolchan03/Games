import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import 'crazy_eights_engine.dart';

class CrazyEightsScreen extends StatefulWidget {
  const CrazyEightsScreen({super.key});
  @override
  State<CrazyEightsScreen> createState() => _CrazyEightsScreenState();
}

class _CrazyEightsScreenState extends State<CrazyEightsScreen> {
  int players = 3;
  AiLevel level = AiLevel.medium;
  late CrazyEightsGame game = CrazyEightsGame(players);
  bool busy = false;
  int generation = 0;

  void _newMatch() => setState(() {
        generation++;
        busy = false;
        game = CrazyEightsGame(players);
      });

  Future<void> _bots() async {
    if (busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && game.winner == null && game.turn != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || token != generation) return;
      setState(() => game.aiTurn(level.index));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  Future<void> _play(PlayingCard c) async {
    if (busy || game.turn != 0 || game.winner != null || !game.canPlay(c)) return;
    Suit? suit;
    if (c.rank == Rank.eight) {
      suit = await showDialog<Suit>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose the new suit'),
          children: [
            for (final s in [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, s),
                child: Text('${s.symbolChar}  ${s.name[0].toUpperCase()}${s.name.substring(1)}',
                    style: TextStyle(fontSize: 20, color: CardView.suitColor(s))),
              ),
          ],
        ),
      );
      if (suit == null) return;
    }
    setState(() => game.play(c, chosen: suit));
    _bots();
  }

  void _draw() {
    if (busy || game.turn != 0 || game.winner != null) return;
    setState(() {
      if (game.draw() == null) game.pass();
    });
    if (game.turn != 0) _bots();
  }

  @override
  Widget build(BuildContext context) {
    final mine = sortedForDisplay(game.hands[0]);
    final myTurn = game.turn == 0 && game.winner == null && !busy;
    final canPlay = game.playable(0).isNotEmpty;
    String status;
    if (game.winner != null) {
      status = game.winner == 0 ? 'You went out — round won!' : 'Player ${game.winner! + 1} wins the round';
    } else if (myTurn) {
      status = canPlay ? 'Your turn: play a card' : 'No playable card — draw';
    } else {
      status = 'Player ${game.turn + 1} is playing…';
    }
    return GameScaffold(
      gameId: 'crazy_eights',
      completed: game.winner == 0,
      title: 'Crazy Eights',
      onNewGame: _newMatch,
      rules: 'Match the top card of the discard pile by suit or rank. Eights '
          'are wild: play one any time and name the next suit. If you cannot '
          'play, draw from the stock until you can. First to get rid of all '
          'their cards wins the round and scores the cards left in the other '
          'hands (eights 50, pictures 10, aces 1, others face value).',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2 players')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
          ],
          selected: {players},
          onSelectionChanged: (s) {
            players = s.first;
            _newMatch();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\n${game.log}', highlight: myTurn || game.winner != null),
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          for (var p = 1; p < players; p++)
            Chip(
              avatar: game.turn == p ? const Icon(Icons.play_arrow, size: 18) : null,
              label: Text('P${p + 1}: ${game.hands[p].length} cards · ${game.scores[p]} pts'),
            ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: _draw,
            child: CardView(faceDown: game.stock.isNotEmpty, width: 70, card: null),
          ),
          const SizedBox(width: 20),
          CardView(card: game.top, width: 70),
          const SizedBox(width: 12),
          Column(children: [
            const Text('Suit'),
            Text(game.activeSuit.symbolChar,
                style: TextStyle(fontSize: 32, color: CardView.suitColor(game.activeSuit))),
          ]),
        ]),
        Text('Stock: ${game.stock.length}', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        HandView(
          cards: mine,
          playable: myTurn ? game.playable(0).toSet() : null,
          onTap: _play,
        ),
        Text('Your score: ${game.scores[0]}', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (game.winner != null)
          FilledButton(
            onPressed: () => setState(() {
              game.deal();
              game.turn = 0;
            }),
            child: const Text('Next round'),
          )
        else
          OutlinedButton.icon(
            onPressed: myTurn && !canPlay ? _draw : null,
            icon: const Icon(Icons.download),
            label: const Text('Draw'),
          ),
      ],
    );
  }
}
