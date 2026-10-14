import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'liars_dice_engine.dart';

class LiarsDiceScreen extends StatefulWidget {
  const LiarsDiceScreen({super.key});
  @override
  State<LiarsDiceScreen> createState() => _LiarsDiceScreenState();
}

class _LiarsDiceScreenState extends State<LiarsDiceScreen> {
  int players = 4;
  AiLevel level = AiLevel.medium;
  late LiarsDiceGame game = LiarsDiceGame(players: players);
  int quantity = 1, face = 2;
  int? loser;
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        loser = null;
        game = LiarsDiceGame(players: players);
        _resetBid();
      });

  void _resetBid() {
    final b = game.bid;
    quantity = b == null ? 1 : b.$1;
    face = b == null ? 2 : b.$2;
    if (!game.validBid(quantity, face)) {
      if (face < 6) {
        face++;
      } else {
        quantity++;
        face = 2;
      }
    }
  }

  Future<void> _bots() async {
    if (busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && game.winner == null && !game.revealing && game.turn != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || token != generation) return;
      final d = game.aiDecide(level.index);
      setState(() {
        if (d == null && game.bid != null) {
          loser = game.challenge();
        } else if (d != null) {
          game.makeBid(d.$1, d.$2);
        }
      });
    }
    if (mounted && token == generation) {
      setState(() {
        busy = false;
        _resetBid();
      });
    }
  }

  void _bid() {
    setState(() => game.makeBid(quantity, face));
    _bots();
  }

  void _challenge() {
    setState(() => loser = game.challenge());
  }

  void _next() {
    setState(() {
      game.nextRound(loser!);
      loser = null;
      _resetBid();
    });
    _bots();
  }

  @override
  Widget build(BuildContext context) {
    final myTurn = game.turn == 0 && !busy && !game.revealing && game.winner == null && game.alive(0);
    String status;
    if (game.winner != null) {
      status = game.winner == 0 ? 'You are the last one with dice — you win!' : '${game.name(game.winner!)} wins the game';
    } else if (!game.alive(0)) {
      status = 'You are out of dice. Watching…';
    } else if (game.revealing) {
      status = game.log;
    } else if (myTurn) {
      status = game.bid == null ? 'Open the bidding' : 'Raise the bid or call liar';
    } else {
      status = '${game.name(game.turn)} is thinking…';
    }
    return GameScaffold(
      gameId: 'liars_dice',
      completed: game.winner == 0,
      title: "Liar's Dice",
      onNewGame: _newGame,
      rules: 'Everyone rolls their dice in secret. Players take turns bidding '
          'how many dice of one face (2–6) are on the whole table — ones are '
          'wild and count as every face. Each bid must raise the quantity, or '
          'keep it and name a higher face. Instead of bidding you can call '
          '"Liar!": all dice are revealed. If the bid was met, the caller '
          'loses a die; otherwise the bidder does. The last player with dice '
          'wins.',
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
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner(status, highlight: myTurn || game.revealing || game.winner != null),
        if (!game.revealing && game.log.isNotEmpty) Text(game.log, textAlign: TextAlign.center),
        for (var p = 1; p < players; p++)
          ListTile(
            leading: Icon(game.turn == p && !game.revealing ? Icons.record_voice_over : Icons.person_outline),
            title: Text('${game.name(p)} · ${game.counts[p]} dice'),
            subtitle: game.revealing
                ? Wrap(children: [for (final d in game.dice[p]) DieFace(d, size: 28)])
                : null,
          ),
        const Divider(),
        Text('Your dice (${game.counts[0]})', textAlign: TextAlign.center),
        Wrap(alignment: WrapAlignment.center, children: [for (final d in game.dice[0]) DieFace(d, size: 46)]),
        const SizedBox(height: 8),
        Text('${game.totalDice} dice on the table', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (game.revealing && game.winner == null)
          FilledButton(onPressed: _next, child: const Text('Next round'))
        else if (myTurn) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton.filledTonal(
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove)),
            SizedBox(width: 56, child: Text('$quantity ×', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
            IconButton.filledTonal(
                onPressed: quantity < game.totalDice ? () => setState(() => quantity++) : null,
                icon: const Icon(Icons.add)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var f = 2; f <= 6; f++)
              DieFace(f, size: 40, held: face == f, onTap: () => setState(() => face = f)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: game.validBid(quantity, face) ? _bid : null,
                child: Text('Bid $quantity × $face'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: game.bid == null ? null : _challenge,
                child: const Text('Liar!'),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}
