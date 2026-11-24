import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'chopsticks_engine.dart';

/// Chopsticks against a perfect (or deliberately imperfect) computer, or
/// another person on the same phone. Tap one of your hands, then an enemy hand
/// to attack, or press Split to re-deal your own fingers.
class ChopsticksScreen extends StatefulWidget {
  const ChopsticksScreen({super.key});

  @override
  State<ChopsticksScreen> createState() => _ChopsticksScreenState();
}

class _ChopsticksScreenState extends State<ChopsticksScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  bool rollover = false;
  bool showAnalysis = false;

  late ChopsticksState game = ChopsticksState.start();
  final Map<String, int> seen = {};
  int? selected; // own hand index chosen to attack with
  bool thinking = false;
  bool drawn = false;
  ChopsticksMove? hint;

  ChopsticksSolver get solver => ChopsticksSolver(rollover);
  bool get over => game.over || drawn;
  bool get humanTurn => !vsComputer || game.turn == 0;

  void _newGame() => setState(() {
        game = ChopsticksState.start(rollover: rollover);
        seen
          ..clear()
          ..[game.key] = 1;
        selected = null;
        hint = null;
        thinking = false;
        drawn = false;
      });

  @override
  void initState() {
    super.initState();
    seen[game.key] = 1;
  }

  void _play(ChopsticksMove move) {
    setState(() {
      game = game.apply(move);
      selected = null;
      hint = null;
      // Three repeats of one position end the game as a draw, so a perfect
      // computer and a cautious player can never loop forever.
      final count = (seen[game.key] ?? 0) + 1;
      seen[game.key] = count;
      if (!game.over && count >= 3) drawn = true;
    });
    _computerReply();
  }

  Future<void> _computerReply() async {
    if (!vsComputer || over || game.turn != 1) return;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || over || game.turn != 1) return;
    final perfect = switch (level) {
      AiLevel.easy => .2,
      AiLevel.medium => .7,
      AiLevel.hard => 1.0,
    };
    final move = rng.nextDouble() < perfect
        ? solver.bestMove(game)!
        : solver.randomMove(game, rng)!;
    setState(() => thinking = false);
    _play(move);
  }

  void _tapOwn(int hand) {
    if (over || thinking || !humanTurn || game.hands[game.turn][hand] == 0) return;
    setState(() {
      selected = selected == hand ? null : hand;
      hint = null;
    });
  }

  void _tapEnemy(int hand) {
    final from = selected;
    if (over || thinking || !humanTurn || from == null) return;
    if (game.hands[1 - game.turn][hand] == 0) return;
    _play(ChopsticksMove.attack(from, hand));
  }

  Future<void> _split() async {
    if (over || thinking || !humanTurn) return;
    final options = [for (final m in game.legalMoves()) if (m.isSplit) m];
    if (options.isEmpty) return;
    final choice = await showModalBottomSheet<ChopsticksMove>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Split your fingers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final m in options)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 56)),
                  onPressed: () => Navigator.pop(context, m),
                  child: Text('${m.splitLow}  ·  ${m.splitHigh}',
                      style: const TextStyle(fontSize: 20)),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (choice != null && mounted) _play(choice);
  }

  void _hint() {
    if (over || thinking || !humanTurn) return;
    final best = solver.bestMove(game);
    setState(() {
      hint = best;
      selected = best != null && !best.isSplit ? best.from : null;
    });
  }

  String get _analysis {
    final v = solver.valueOf(game);
    final who = humanTurn ? 'The player to move' : 'The computer';
    if (v > 0) return '$who wins in ${(v + 1) ~/ 2} move${(v + 1) ~/ 2 == 1 ? '' : 's'} with best play.';
    if (v < 0) return '$who is losing with best play.';
    return 'Dead level: best play from here is a draw.';
  }

  @override
  Widget build(BuildContext context) {
    final names = vsComputer ? ['You', 'Computer'] : ['Player 1', 'Player 2'];
    final status = drawn
        ? 'Draw: the position repeated three times.'
        : game.over
            ? '${names[game.winner!]} win${game.winner == 0 && vsComputer ? '' : 's'}!'
            : thinking
                ? 'Computer is thinking…'
                : selected == null
                    ? '${names[game.turn]}: pick one of your hands, or Split'
                    : '${names[game.turn]}: now tap a hand to attack';
    final mover = game.turn;
    final foe = 1 - game.turn;
    // Bottom row = the player to move (human, or whoever is up in 2-player).
    final bottom = vsComputer ? 0 : mover;
    final top = 1 - bottom;
    final canAct = !over && !thinking && humanTurn;

    return GameScaffold(
      gameId: 'chopsticks',
      completed: game.over && (game.winner == 0 || !vsComputer),
      title: 'Chopsticks',
      onNewGame: _newGame,
      confirmNewGame: seen.length > 1 && !over,
      rules: 'Each hand starts with one finger. On your turn either ATTACK: '
          'tap one of your hands, then an enemy hand, and the enemy hand gains '
          'as many fingers as yours shows. A hand with 5 or more fingers is out '
          '(in Rollover it wraps around instead). Or SPLIT: re-deal the '
          'fingers you have between your two hands. Knock out both enemy hands '
          'to win. The game is small enough to be fully solved: Hard never '
          'makes a mistake, and "Show analysis" tells you who is winning.',
      children: [
        StatusBanner(status, highlight: over),
        _HandsRow(
          label: names[top],
          hands: game.hands[top],
          active: !over && game.turn == top,
          targetable: canAct && selected != null && top == foe,
          onTap: _tapEnemy,
          hintHand: hint != null && !hint!.isSplit ? hint!.to : null,
        ),
        const SizedBox(height: 8),
        _HandsRow(
          label: names[bottom],
          hands: game.hands[bottom],
          active: !over && game.turn == bottom,
          selectedHand: bottom == mover ? selected : null,
          selectable: canAct && bottom == mover,
          onTap: _tapOwn,
          hintHand: hint != null && !hint!.isSplit ? hint!.from : null,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: canAct ? _split : null,
              icon: const Icon(Icons.call_split_rounded),
              label: const Text('Split'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: canAct ? _hint : null,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Hint'),
            ),
          ),
        ]),
        if (hint?.isSplit ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Hint: split to ${hint!.splitLow} · ${hint!.splitHigh}'),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show analysis'),
          subtitle: const Text('Who wins with perfect play from here'),
          value: showAnalysis,
          onChanged: (v) => setState(() => showAnalysis = v),
        ),
        if (showAnalysis && !over) Text(_analysis),
        const Divider(height: 24),
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Classic')),
            ButtonSegment(value: true, label: Text('Rollover')),
          ],
          selected: {rollover},
          onSelectionChanged: (s) {
            rollover = s.first;
            _newGame();
          },
        ),
      ],
    );
  }
}

class _HandsRow extends StatelessWidget {
  const _HandsRow({
    required this.label,
    required this.hands,
    required this.active,
    required this.onTap,
    this.selectedHand,
    this.selectable = false,
    this.targetable = false,
    this.hintHand,
  });

  final String label;
  final List<int> hands;
  final bool active;
  final void Function(int hand) onTap;
  final int? selectedHand;
  final bool selectable;
  final bool targetable;
  final int? hintHand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
              color: active ? theme.colorScheme.primary : null)),
      const SizedBox(height: 6),
      Row(children: [
        for (var i = 0; i < 2; i++) ...[
          if (i == 1) const SizedBox(width: 12),
          Expanded(
            child: _Hand(
              fingers: hands[i],
              selected: selectedHand == i,
              highlight: (selectable && hands[i] > 0) || (targetable && hands[i] > 0),
              hinted: hintHand == i,
              onTap: () => onTap(i),
              semantics: '$label hand ${i + 1}, ${hands[i] == 0 ? 'out' : '${hands[i]} fingers'}',
            ),
          ),
        ],
      ]),
    ]);
  }
}

class _Hand extends StatelessWidget {
  const _Hand({
    required this.fingers,
    required this.selected,
    required this.highlight,
    required this.hinted,
    required this.onTap,
    required this.semantics,
  });

  final int fingers;
  final bool selected, highlight, hinted;
  final VoidCallback onTap;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final out = fingers == 0;
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: semantics,
      child: Material(
        color: out
            ? s.surfaceContainerHighest
            : selected
                ? s.primaryContainer
                : s.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: hinted
                ? s.tertiary
                : selected || highlight
                    ? s.primary
                    : s.outline,
            width: selected || hinted ? 4 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            height: 112,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              out
                  ? Text('OUT',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800, color: s.outline))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < fingers; i++)
                        Container(
                          width: 14,
                          height: 36 + (i == 1 || i == 2 ? 8.0 : 0),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: s.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ]),
              const SizedBox(height: 8),
              Text('$fingers',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }
}
