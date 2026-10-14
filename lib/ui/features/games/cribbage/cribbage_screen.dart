import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import 'cribbage_engine.dart';

class CribbageScreen extends StatefulWidget {
  const CribbageScreen({super.key});
  @override
  State<CribbageScreen> createState() => _CribbageScreenState();
}

class _CribbageScreenState extends State<CribbageScreen> {
  AiLevel level = AiLevel.medium;
  CribbageGame game = CribbageGame();
  final Set<PlayingCard> chosen = {};
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        chosen.clear();
        game = CribbageGame();
      });

  Future<void> _computer() async {
    if (busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && game.phase == CribPhase.pegging && game.turn == 1) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || token != generation) return;
      setState(() => game.play(game.aiPeg(level.index)));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _tap(PlayingCard c) {
    if (busy) return;
    if (game.phase == CribPhase.discard) {
      setState(() {
        if (!chosen.remove(c) && chosen.length < 2) chosen.add(c);
      });
    } else if (game.phase == CribPhase.pegging && game.turn == 0 && game.canPlay(0, c)) {
      setState(() => game.play(c));
      _computer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = game;
    final theme = Theme.of(context);
    final myHand = g.phase == CribPhase.discard ? g.hands[0] : g.phase == CribPhase.pegging ? g.pegHands[0] : g.hands[0];
    String status;
    switch (g.phase) {
      case CribPhase.discard:
        status = 'Pick 2 cards for ${g.dealer == 0 ? 'your' : 'the computer\'s'} crib';
      case CribPhase.pegging:
        status = g.turn == 0 ? 'Your turn — count ${g.count}' : 'Computer is pegging…';
      case CribPhase.show:
        status = 'The show: ${g.showLog.join(' · ')}';
      case CribPhase.gameOver:
        status = g.winner == 0 ? 'You reached 121 — you win!' : 'The computer reached 121';
    }
    return GameScaffold(
      gameId: 'cribbage',
      completed: g.winner == 0,
      title: 'Cribbage',
      onNewGame: _newGame,
      rules: 'Two players race to 121 points. Each is dealt six cards and '
          'puts two into the dealer\'s crib; a starter card is cut (a jack '
          'gives the dealer 2). In the play, take turns laying cards with a '
          'running total up to 31: score 2 for 15 or 31, 2/6/12 for pairs, '
          'and runs of three or more; 1 for the last card. Then hands are '
          'shown with the starter: fifteens (2 each), pairs (2), runs, '
          'flushes (4 or 5) and "nobs" (jack of the starter\'s suit, 1). The '
          'dealer also scores the crib.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\n${g.log}', highlight: g.phase == CribPhase.gameOver || (g.phase == CribPhase.pegging && g.turn == 0)),
        // Score track.
        for (final p in [1, 0])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 84, child: Text('${g.name(p)} ${g.scores[p]}')),
              Expanded(child: LinearProgressIndicator(value: g.scores[p] / 121, minHeight: 10, borderRadius: BorderRadius.circular(5))),
            ]),
          ),
        const SizedBox(height: 8),
        Text('Computer${g.dealer == 1 ? ' (dealer)' : ''}', textAlign: TextAlign.center),
        HandView(
          cards: g.phase == CribPhase.show || g.phase == CribPhase.gameOver ? g.hands[1] : (g.phase == CribPhase.pegging ? g.pegHands[1] : g.hands[1]),
          cardWidth: 40,
          onTap: null,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [const Text('Starter'), CardView(card: g.starter, faceDown: g.starter == null, width: 48)]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(children: [
              Text('Count ${g.count}'),
              Wrap(alignment: WrapAlignment.center, children: [for (final c in g.pile) CardView(card: c, width: 34)]),
            ]),
          ),
          const SizedBox(width: 16),
          Column(children: [
            Text(g.dealer == 0 ? 'Your crib' : 'Crib'),
            if (g.phase == CribPhase.show || g.phase == CribPhase.gameOver)
              Wrap(children: [for (final c in g.crib) CardView(card: c, width: 26)])
            else
              CardView(faceDown: g.crib.isNotEmpty, width: 34),
          ]),
        ]),
        const SizedBox(height: 8),
        Text('Your hand${g.dealer == 0 ? ' (dealer)' : ''}', textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
        HandView(
          cards: sortedForDisplay(myHand),
          selected: chosen,
          playable: g.phase == CribPhase.pegging && g.turn == 0 ? g.pegHands[0].where((c) => g.canPlay(0, c)).toSet() : null,
          onTap: _tap,
        ),
        const SizedBox(height: 8),
        if (g.phase == CribPhase.discard)
          FilledButton(
            onPressed: chosen.length == 2
                ? () {
                    setState(() {
                      g.discard(chosen.toList(), level.index);
                      chosen.clear();
                    });
                    _computer();
                  }
                : null,
            child: Text('Send ${chosen.length}/2 to the crib'),
          ),
        if (g.phase == CribPhase.show)
          FilledButton(
            onPressed: () {
              setState(g.nextHand);
            },
            child: const Text('Next hand'),
          ),
        if (g.phase == CribPhase.gameOver)
          FilledButton(onPressed: _newGame, child: const Text('New game')),
      ],
    );
  }
}
