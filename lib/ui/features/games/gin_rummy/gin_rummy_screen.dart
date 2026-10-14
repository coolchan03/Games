import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import 'gin_rummy_engine.dart';

class GinRummyScreen extends StatefulWidget {
  const GinRummyScreen({super.key});
  @override
  State<GinRummyScreen> createState() => _GinRummyScreenState();
}

class _GinRummyScreenState extends State<GinRummyScreen> {
  AiLevel level = AiLevel.medium;
  GinRummyGame game = GinRummyGame();
  PlayingCard? selected;
  bool busy = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computer());
  }

  void _newMatch() {
    setState(() {
      generation++;
      busy = false;
      selected = null;
      game = GinRummyGame();
    });
    _computer();
  }

  Future<void> _computer() async {
    if (busy || game.turn != 1 || game.phase == GinPhase.handOver) return;
    final token = generation;
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted || token != generation) return;
    setState(() {
      game.aiTurn(level.index);
      busy = false;
    });
  }

  void _discard({bool knock = false}) {
    final c = selected;
    if (c == null) return;
    setState(() {
      game.discardCard(c, knock: knock);
      selected = null;
    });
    _computer();
  }

  /// Hand ordered as melds first, then deadwood.
  List<PlayingCard> _ordered(List<PlayingCard> hand) {
    final best = bestMelds(hand);
    return [for (final m in best.melds) ...m, ...sortedForDisplay(best.deadwood)];
  }

  @override
  Widget build(BuildContext context) {
    final myTurn = game.turn == 0 && !busy && game.phase != GinPhase.handOver;
    final best = bestMelds(game.hands[0]);
    final over = game.phase == GinPhase.handOver;
    String status;
    if (over) {
      status = game.result!.text;
      if (game.matchOver) status += game.scores[0] > game.scores[1] ? '\nYou win the match!' : '\nComputer wins the match.';
    } else if (!myTurn) {
      status = 'Computer is playing…';
    } else if (game.phase == GinPhase.draw) {
      status = 'Draw from the stock or take the ${game.discard.last.symbolString()}';
    } else {
      status = selected == null ? 'Tap a card to discard' : 'Discard ${selected!.symbolString()}?';
    }
    final canKnock = myTurn && selected != null && game.canKnock(selected!);
    final ginAfter = selected != null && game.phase == GinPhase.discard && game.deadwoodWithout(0, selected!) == 0;
    return GameScaffold(
      title: 'Gin Rummy',
      onNewGame: _newMatch,
      rules: 'Two players, ten cards each. On your turn draw one card (from '
          'the stock or the top discard) and then discard one. Group cards '
          'into melds: three or four of a kind, or three or more in sequence '
          'in one suit (ace is low). Unmatched cards are deadwood (aces 1, '
          'pictures 10).\n\nWhen your deadwood is 10 or less you may knock '
          'with your discard. The opponent then lays off cards on your melds. '
          'You score the difference in deadwood; if theirs is equal or lower '
          'they "undercut" you for 25 + difference. Going gin (no deadwood) '
          'scores 25 + their deadwood. First to 100 wins.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\nYou ${game.scores[0]} · Computer ${game.scores[1]}',
            highlight: myTurn || over),
        Text(over ? 'Computer\'s hand' : 'Computer: ${game.hands[1].length} cards', textAlign: TextAlign.center),
        HandView(
          cards: over ? _ordered(game.hands[1]) : game.hands[1],
          cardWidth: 44,
          selected: over ? game.laidOff.toSet() : const {},
          onTap: null,
        ),
        if (over)
          Text('Melds: ${bestMelds(game.hands[1]).melds.map((m) => m.map((c) => c.symbolString()).join(' ')).join(' | ')}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: myTurn && game.phase == GinPhase.draw ? () => setState(game.drawStock) : null,
            child: CardView(faceDown: true, width: 64),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: myTurn && game.phase == GinPhase.draw ? () => setState(game.drawDiscard) : null,
            child: CardView(card: game.discard.isEmpty ? null : game.discard.last, width: 64),
          ),
        ]),
        Text('Stock ${game.stock.length}', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('Your hand · deadwood ${best.points}', textAlign: TextAlign.center),
        HandView(
          cards: _ordered(game.hands[0]),
          selected: selected == null ? const {} : {selected!},
          onTap: myTurn && game.phase == GinPhase.discard ? (c) => setState(() => selected = c) : null,
        ),
        if (best.melds.isNotEmpty)
          Text('Melds: ${best.melds.map((m) => m.map((c) => c.symbolString()).join(' ')).join(' | ')}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        if (over)
          FilledButton(
            onPressed: game.matchOver
                ? _newMatch
                : () {
                    setState(() {
                      game.deal();
                      selected = null;
                    });
                    _computer();
                  },
            child: Text(game.matchOver ? 'New match' : 'Next hand'),
          )
        else if (myTurn && game.phase == GinPhase.draw)
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => setState(game.drawStock), child: const Text('Draw stock')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                  onPressed: () => setState(game.drawDiscard), child: const Text('Take discard')),
            ),
          ])
        else
          Row(children: [
            Expanded(
              child: FilledButton.tonal(
                  onPressed: myTurn && selected != null ? _discard : null, child: const Text('Discard')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: canKnock ? () => _discard(knock: true) : null,
                child: Text(ginAfter ? 'Gin!' : 'Knock'),
              ),
            ),
          ]),
      ],
    );
  }
}
