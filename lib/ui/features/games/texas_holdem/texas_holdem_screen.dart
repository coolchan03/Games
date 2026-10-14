import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import '../common/poker_eval.dart';
import 'holdem_engine.dart';

/// No-limit Texas Hold'em against three computer players, virtual chips only.
class TexasHoldemScreen extends StatefulWidget {
  const TexasHoldemScreen({super.key});
  @override
  State<TexasHoldemScreen> createState() => _TexasHoldemScreenState();
}

class _TexasHoldemScreenState extends State<TexasHoldemScreen> {
  AiLevel level = AiLevel.medium;
  late HoldemGame game;
  bool busy = false;
  double raiseTo = 0;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    generation++;
    busy = false;
    game = HoldemGame(names: const ['You', 'Ada', 'Ben', 'Cleo']);
    game.startHand();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runBots());
  }

  Future<void> _runBots() async {
    final token = generation;
    if (busy) return;
    busy = true;
    while (mounted && token == generation && !game.handOver && game.current != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || token != generation) return;
      final action = game.botAction(game.current, level.index);
      setState(() => game.act(action));
    }
    if (mounted && token == generation) {
      setState(() {
        busy = false;
        if (!game.handOver) raiseTo = game.minRaiseTo(0).toDouble();
      });
    }
  }

  void _act(PokerAction a) {
    if (busy || game.handOver || game.current != 0) return;
    setState(() => game.act(a));
    _runBots();
  }

  void _nextHand() {
    setState(game.startHand);
    _runBots();
  }

  Widget _seat(int i) {
    final p = game.players[i];
    final colors = Theme.of(context).colorScheme;
    final showCards = game.handOver && p.inHand && game.board.length == 5 && game.results.any((r) => r.rank != null);
    final won = game.handOver && game.results.any((r) => r.winners.contains(i));
    return Container(
      width: 104,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: won
            ? colors.tertiaryContainer
            : !game.handOver && game.current == i
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${p.chips} chips', style: const TextStyle(fontSize: 12)),
        if (i == game.dealer) const Text('Dealer', style: TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < p.hole.length; k++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: p.folded
                  ? const SizedBox(width: 30, height: 42)
                  : CardView(card: p.hole[k], faceDown: !showCards, width: 30),
            ),
        ]),
        Text(
          p.bet > 0 && !game.handOver ? '${p.lastAction} · ${p.bet}' : p.lastAction,
          style: const TextStyle(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = game.players[0];
    final myTurn = !busy && !game.handOver && game.current == 0;
    final call = game.toCall(0);
    String status;
    if (game.handOver) {
      final lines = <String>[];
      for (final r in game.results) {
        final names = r.winners.map((w) => game.players[w].name).join(' & ');
        lines.add('$names ${r.winners.length == 1 && r.winners.first == 0 ? 'win' : 'wins'} '
            '${r.amount}${r.rank == null ? '' : ' with ${r.rank!.label.toLowerCase()}'}');
      }
      status = lines.join('\n');
      if (game.matchOver) {
        status += me.chips == 0 ? '\nYou are out of chips.' : '\nYou won every chip!';
      }
    } else if (myTurn) {
      status = call > 0 ? 'Your move — $call to call' : 'Your move';
    } else {
      status = '${game.players[game.current].name} is thinking…';
    }
    final myRank = me.hole.length == 2 && game.board.length >= 3
        ? bestHand([...me.hole, ...game.board]).label
        : null;
    final minR = game.handOver ? 0 : game.minRaiseTo(0);
    final maxR = game.handOver ? 0 : game.maxRaiseTo(0);
    final canRaise = myTurn && game.canRaise(0);
    final raiseValue = raiseTo.clamp(minR.toDouble(), maxR.toDouble());
    return GameScaffold(
      title: "Texas Hold'em",
      onNewGame: () => setState(_newGame),
      rules: "No-limit Texas Hold'em for virtual chips only — no real money. "
          'Everyone gets two private cards. Five shared cards are dealt in '
          'stages (flop, turn, river) with a betting round before and after '
          'each. Make the best five-card hand from your two cards and the '
          'board, or make everyone else fold.\n\nHand ranks, high to low: '
          'straight flush, four of a kind, full house, flush, straight, '
          'three of a kind, two pair, pair, high card. Blinds are 10/20 and '
          'side pots are handled automatically when someone is all-in.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [
            for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label)),
          ],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [for (var i = 1; i < game.players.length; i++) _seat(i)],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E6B45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < 5; k++)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: CardView(card: k < game.board.length ? game.board[k] : null, width: 48),
                ),
            ]),
            const SizedBox(height: 6),
            Text('Pot ${game.handOver ? game.results.fold(0, (s, r) => s + r.amount) : game.pot}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
        StatusBanner(status, highlight: myTurn || game.handOver),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final c in me.hole)
            Padding(padding: const EdgeInsets.all(3), child: CardView(card: c, width: 64)),
          const SizedBox(width: 12),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${me.chips} chips', style: Theme.of(context).textTheme.titleMedium),
            if (me.bet > 0 && !game.handOver) Text('In this round: ${me.bet}'),
            if (myRank != null) Text(myRank),
            if (game.dealer == 0) const Text('Dealer'),
          ])),
        ]),
        const SizedBox(height: 8),
        if (game.handOver)
          FilledButton(
            onPressed: game.matchOver ? () => setState(_newGame) : _nextHand,
            child: Text(game.matchOver ? 'New game' : 'Next hand'),
          )
        else ...[
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: myTurn ? () => _act(const PokerAction(ActionType.fold)) : null,
                child: const Text('Fold'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: myTurn
                    ? () => _act(PokerAction(call == 0 ? ActionType.check : ActionType.call))
                    : null,
                child: Text(call == 0 ? 'Check' : 'Call ${call > me.chips ? me.chips : call}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: canRaise
                    ? () => _act(PokerAction(ActionType.raise, raiseValue.round()))
                    : null,
                child: Text(raiseValue.round() >= maxR ? 'All-in' : 'Raise ${raiseValue.round()}'),
              ),
            ),
          ]),
          if (canRaise && maxR > minR)
            Slider(
              value: raiseValue,
              min: minR.toDouble(),
              max: maxR.toDouble(),
              divisions: ((maxR - minR) ~/ 10).clamp(1, 200),
              label: '${raiseValue.round()}',
              onChanged: (v) => setState(() => raiseTo = v),
            ),
        ],
      ],
    );
  }
}
