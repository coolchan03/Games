import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/game_kit.dart';
import 'blackjack_engine.dart';

/// Offline blackjack: virtual chips only, no real-money wagering.
class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});
  @override
  State<BlackjackScreen> createState() => _BlackjackState();
}

class _BlackjackState extends State<BlackjackScreen> {
  BlackjackGame game = BlackjackGame();
  bool showAdvice = false;

  Widget _cards(List cards, {bool hideHole = false}) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < cards.length; i++)
            CardView(card: cards[i], faceDown: hideHole && i == 1, width: 58),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = game;
    final dealerTotal = handTotal(g.dealer).$1;
    final hideHole = g.inRound;
    return GameScaffold(
      gameId: 'blackjack',
      completed: !g.inRound && g.summary.startsWith('You win'),
      title: 'Blackjack',
      onNewGame: () => setState(() => game = BlackjackGame()),
      rules: 'Virtual chips only — no real money. Get closer to 21 than the '
          'dealer without going over. Pictures count 10, aces 1 or 11. A '
          'two-card 21 is blackjack and pays 3 to 2. The dealer draws to 16 '
          'and stands on all 17s. Double: double your bet and take exactly '
          'one more card. Split: a pair becomes two hands (split aces get '
          'one card each). Six-deck shoe. The Advice switch shows basic '
          'strategy for your current hand.',
      children: [
        StatusBanner(
          g.inRound
              ? 'Your hand: ${g.hand.total}${g.hand.soft ? ' (soft)' : ''}'
                  '${g.hands.length > 1 ? ' · hand ${g.active + 1} of 2' : ''}'
              : g.summary.isEmpty
                  ? 'Place your bet and deal'
                  : g.summary,
          highlight: !g.inRound && g.summary.isNotEmpty,
        ),
        Text('Dealer${hideHole ? '' : ' · $dealerTotal'}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        if (g.dealer.isNotEmpty) _cards(g.dealer, hideHole: hideHole),
        const SizedBox(height: 16),
        for (var h = 0; h < g.hands.length; h++) ...[
          Text(
            '${g.hands.length > 1 ? 'Hand ${h + 1} · ' : 'You · '}${g.hands[h].total} · bet ${g.hands[h].bet}'
            '${g.hands[h].outcome.isEmpty ? '' : ' · ${g.hands[h].outcome}'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
                color: g.inRound && h == g.active && g.hands.length > 1 ? theme.colorScheme.primary : null),
          ),
          const SizedBox(height: 6),
          _cards(g.hands[h].cards),
          const SizedBox(height: 10),
        ],
        Text('Chips: ${g.chips}', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        SwitchListTile(
          title: const Text('Show basic-strategy advice'),
          value: showAdvice,
          onChanged: (v) => setState(() => showAdvice = v),
        ),
        if (showAdvice && g.inRound)
          Text('Advice: ${g.advice()}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (g.inRound)
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () => setState(g.hit), child: const Text('Hit')),
            FilledButton.tonal(onPressed: () => setState(g.stand), child: const Text('Stand')),
            OutlinedButton(onPressed: g.canDouble ? () => setState(g.doubleDown) : null, child: const Text('Double')),
            OutlinedButton(onPressed: g.canSplit ? () => setState(g.split) : null, child: const Text('Split')),
          ])
        else ...[
          SegmentedButton<int>(
            segments: [for (final b in const [10, 25, 50, 100, 250]) ButtonSegment(value: b, label: Text('$b'))],
            selected: {g.bet},
            onSelectionChanged: (s) => setState(() => g.bet = s.first),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: g.canDeal ? () => setState(g.deal) : null,
            icon: const Icon(Icons.style),
            label: Text('Deal (bet ${g.bet})'),
          ),
          if (g.chips < g.bet)
            TextButton(
              onPressed: () => setState(() => g.chips += 1000),
              child: const Text('Out of chips — take 1000 more (free)'),
            ),
        ],
      ],
    );
  }
}
