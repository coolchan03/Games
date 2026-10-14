import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';

/// Shut the Box: roll two dice (one die once 7-9 are shut) and shut tiles
/// that add up to the roll. Score is the sum of open tiles; lower is better.
class ShutTheBoxGame {
  ShutTheBoxGame({Random? random}) : rng = random ?? Random();
  final Random rng;
  final open = List.filled(10, true); // index 1..9 used
  List<int> dice = [];
  final Set<int> chosen = {};
  bool over = false;

  int get roll => dice.fold(0, (a, b) => a + b);
  int get score => [for (var t = 1; t <= 9; t++) if (open[t]) t].fold(0, (a, b) => a + b);
  bool get shut => score == 0;
  bool get canUseOneDie => !open[7] && !open[8] && !open[9];

  /// Can [target] be made from distinct open tiles?
  bool reachable(int target, [int from = 9]) {
    if (target == 0) return true;
    for (var t = min(from, target); t >= 1; t--) {
      if (open[t] && reachable(target - t, t - 1)) return true;
    }
    return false;
  }

  void rollDice({int count = 2}) {
    dice = [for (var i = 0; i < count; i++) rng.nextInt(6) + 1];
    chosen.clear();
    if (!reachable(roll)) over = true;
  }

  void toggle(int t) {
    if (!open[t] || dice.isEmpty || over) return;
    if (!chosen.remove(t)) chosen.add(t);
  }

  bool get chosenValid => chosen.fold(0, (a, b) => a + b) == roll;

  void confirm() {
    if (!chosenValid) return;
    for (final t in chosen) {
      open[t] = false;
    }
    chosen.clear();
    dice = [];
    if (shut) over = true;
  }
}

class ShutTheBoxScreen extends StatefulWidget {
  const ShutTheBoxScreen({super.key});
  @override
  State<ShutTheBoxScreen> createState() => _ShutTheBoxScreenState();
}

class _ShutTheBoxScreenState extends State<ShutTheBoxScreen> {
  ShutTheBoxGame game = ShutTheBoxGame();
  int? best;

  void _finish() {
    if (game.over && (best == null || game.score < best!)) best = game.score;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String status;
    if (game.over) {
      status = game.shut ? 'You shut the box! Perfect score 0' : 'No way to make ${game.roll} — score ${game.score}';
    } else if (game.dice.isEmpty) {
      status = 'Roll the dice';
    } else {
      status = 'Rolled ${game.roll} — shut tiles that add up to ${game.roll}';
    }
    return GameScaffold(
      gameId: 'shut_the_box',
      completed: game.shut,
      title: 'Shut the Box',
      onNewGame: () => setState(() => game = ShutTheBoxGame()),
      rules: 'Tiles 1–9 start open. Roll two dice, then shut any open tiles '
          'whose numbers add up to the total. Once 7, 8 and 9 are shut you '
          'may roll a single die. The round ends when you cannot make the '
          'total; your score is the sum of the open tiles (lower is better). '
          'Shut every tile to win outright.',
      children: [
        StatusBanner(status, highlight: game.over),
        if (best != null) Text('Best score this session: $best', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(children: [
          for (var t = 1; t <= 9; t++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => game.toggle(t)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 74,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: !game.open[t]
                        ? colors.surfaceContainerHighest
                        : game.chosen.contains(t)
                            ? colors.primary
                            : const Color(0xFFD7B98E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6D4C41)),
                  ),
                  alignment: Alignment.center,
                  child: Text(game.open[t] ? '$t' : '',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: game.chosen.contains(t) ? colors.onPrimary : Colors.black87)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final d in game.dice) DieFace(d, size: 56),
        ]),
        const SizedBox(height: 12),
        if (!game.over && game.dice.isEmpty)
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            FilledButton(
                onPressed: () => setState(() {
                      game.rollDice();
                      _finish();
                    }),
                child: const Text('Roll two dice')),
            if (game.canUseOneDie)
              OutlinedButton(
                  onPressed: () => setState(() {
                        game.rollDice(count: 1);
                        _finish();
                      }),
                  child: const Text('Roll one die')),
          ]),
        if (!game.over && game.dice.isNotEmpty)
          FilledButton(
            onPressed: game.chosenValid
                ? () => setState(() {
                      game.confirm();
                      _finish();
                    })
                : null,
            child: const Text('Shut tiles'),
          ),
        if (game.over)
          FilledButton(onPressed: () => setState(() => game = ShutTheBoxGame()), child: const Text('Play again')),
      ],
    );
  }
}
