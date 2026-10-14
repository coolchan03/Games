import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import 'video_poker_engine.dart';

/// Jacks or Better video poker for virtual credits only.
class VideoPokerScreen extends StatefulWidget {
  const VideoPokerScreen({super.key});
  @override
  State<VideoPokerScreen> createState() => _VideoPokerScreenState();
}

class _VideoPokerScreenState extends State<VideoPokerScreen> {
  VideoPokerGame game = VideoPokerGame();
  String? advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = game.hand.isEmpty
        ? 'Press Deal to start'
        : !game.drawn
            ? 'Tap cards to hold, then Draw'
            : game.lastWin > 0
                ? '${payoutName(game.hand)}! You win ${game.lastWin}'
                : 'No win — deal again';
    return GameScaffold(
      gameId: 'video_poker',
      completed: game.drawn && game.lastWin > 0,
      title: 'Video Poker',
      onNewGame: () => setState(() {
        game = VideoPokerGame();
        advice = null;
      }),
      rules: 'Jacks or Better, played for virtual credits only. You are dealt '
          'five cards; hold any of them and draw replacements once. The '
          'final hand pays according to the table (a pair of jacks or higher '
          'is the smallest win). A five-credit royal flush pays 4000.\n\n'
          'The Advice button computes the hold with the best expected payout.',
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(2)},
          children: [
            for (final e in jacksOrBetterPays.entries)
              TableRow(
                decoration: game.drawn && game.hand.isNotEmpty && payoutName(game.hand) == e.key
                    ? BoxDecoration(color: theme.colorScheme.tertiaryContainer)
                    : null,
                children: [
                  Text(e.key),
                  Text(
                    e.key == 'Royal flush' && game.bet == 5 ? '4000' : '${e.value * game.bet}',
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
          ],
        ),
        StatusBanner(result, highlight: game.drawn && game.lastWin > 0),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.all(3),
              child: Column(children: [
                CardView(
                  card: game.hand.isEmpty ? null : game.hand[i],
                  faceDown: game.hand.isEmpty,
                  width: 58,
                  selected: game.held[i] && !game.drawn,
                  onTap: () => setState(() {
                    game.toggle(i);
                    advice = null;
                  }),
                ),
                const SizedBox(height: 4),
                Text(game.held[i] && !game.drawn ? 'HELD' : '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ]),
            ),
        ]),
        Text('Credits ${game.credits}', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        if (advice != null) Text(advice!, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: SegmentedButton<int>(
              segments: [for (final b in const [1, 2, 5]) ButtonSegment(value: b, label: Text('Bet $b'))],
              selected: {game.bet},
              onSelectionChanged: game.drawn ? (s) => setState(() => game.bet = s.first) : null,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: game.drawn
                  ? null
                  : () => setState(() {
                        final h = game.bestHold();
                        game.held = h;
                        advice = 'Best expected value: hold '
                            '${h.where((x) => x).length} card${h.where((x) => x).length == 1 ? '' : 's'}';
                      }),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Advice'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: game.drawn
                  ? (game.canDeal ? () => setState(game.deal) : null)
                  : () => setState(() {
                        game.draw();
                        advice = null;
                      }),
              child: Text(game.drawn ? 'Deal' : 'Draw'),
            ),
          ),
        ]),
        if (game.drawn && !game.canDeal)
          TextButton(
              onPressed: () => setState(() => game.credits += 200),
              child: const Text('Out of credits — refill 200 (free)')),
      ],
    );
  }
}
