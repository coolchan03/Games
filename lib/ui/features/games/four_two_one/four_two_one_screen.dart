import 'package:flutter/material.dart';
import '../common/game_kit.dart';
import '../shared/game_storage.dart';
import 'four_two_one_engine.dart';

class FourTwoOneScreen extends StatefulWidget {
  const FourTwoOneScreen({super.key});
  @override
  State<FourTwoOneScreen> createState() => _FourTwoOneScreenState();
}

class _FourTwoOneScreenState extends State<FourTwoOneScreen> {
  int players = 2, epoch = 0;
  bool computer = true, busy = false, ready = false;
  late FourTwoOneGame game;
  String saveStatus = 'Loading table...';

  @override
  void initState() {
    super.initState();
    game = FourTwoOneGame(players: players);
    restore();
  }

  Future<void> restore() async {
    try {
      final data = await GameStorage.load('four_two_one_v1');
      if (!mounted) return;
      if (data != null) {
        game = FourTwoOneGame.fromJson(
            Map<String, dynamic>.from(data['game'] as Map));
        players = game.players;
        computer = data['computer'] == true;
      }
      saveStatus = data == null ? 'Saved only on this device' : 'Game restored';
    } catch (_) {
      saveStatus = 'Save invalid; new game started';
    }
    if (!mounted) return;
    setState(() => ready = true);
    runComputer();
  }

  Future<void> save() async {
    try {
      await GameStorage.save('four_two_one_v1', {
        'game': game.toJson(), 'computer': computer,
      });
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Could not save this turn');
    }
  }

  bool get canAct => ready && !busy && !game.finished &&
      (!computer || game.current == 0);

  void newGame() {
    epoch++;
    setState(() {
      game = FourTwoOneGame(players: players);
      busy = false;
    });
    save();
  }

  void roll() {
    if (!canAct || !game.roll()) return;
    setState(() {});
    save();
  }

  void stop() {
    if (!canAct || !game.stop()) return;
    setState(() {});
    save();
    runComputer();
  }

  Future<void> runComputer() async {
    if (!mounted || !ready || busy || !computer ||
        game.finished || game.current == 0) return;
    final token = ++epoch;
    setState(() => busy = true);
    for (var attempts = 0; attempts < 30; attempts++) {
      if (!mounted || token != epoch || game.finished || game.current == 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || token != epoch) return;
      setState(() => game.autoTurn());
    }
    if (!mounted || token != epoch) return;
    setState(() => busy = false);
    await save();
  }

  @override
  void dispose() {
    epoch++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = game.finished
        ? 'Game over — player ${game.loserSeat == null ? "?" : game.loserSeat! + 1} has the remaining chips'
        : '${game.phase == FourTwoOnePhase.charge ? "Charge" : "Discharge"} '
          'round ${game.roundNumber} — Player ${game.current + 1} '
          '(${game.rollsUsed}/${game.rollLimit} throws)';
    return GameScaffold(
      gameId: 'four_two_one',
      completed: game.finished && game.loserSeat != 0,
      title: '421',
      onNewGame: newGame,
      rules: 'OBJECTIVE: Avoid holding the 21 chips. '
          'HOW TO PLAY: Tap Roll to throw three dice, tap a die to hold it, '
          'then reroll the rest up to three times. Press Keep result to '
          'finish your turn. The first player sets the number of throws '
          'allowed to everyone else in that round. During CHARGE the '
          'lowest hand takes chips from the bank. During DISCHARGE '
          'the highest hand passes chips to the lowest hand. '
          'Winning hand determines the number: 421 = 10, triple aces = 7, '
          'two aces or three matching dice = shown pip value, a run = 2, '
          'other hands = 1. The player left with chips loses. '
          'If lowest players tie, replay the round. '
          'Play with 2-6 people on one device or with casual computer opponents.',
      children: [
        Row(children: [
          Expanded(child: DropdownButton<int>(
            isExpanded: true,
            value: players,
            items: [for (var n = 2; n <= 6; n++)
              DropdownMenuItem(value: n, child: Text('$n players'))],
            onChanged: busy ? null : (value) {
              if (value == null) return;
              setState(() => players = value);
              newGame();
            },
          )),
          const SizedBox(width: 12),
          Expanded(child: SwitchListTile(
            dense: true,
            title: const Text('Computer'),
            value: computer,
            onChanged: busy ? null : (value) {
              setState(() => computer = value);
              newGame();
            },
          )),
        ]),
        StatusBanner(result, highlight: game.finished),
        Text(game.message, textAlign: TextAlign.center),
        Text(saveStatus, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
        Text('Central bank: ${game.bank} chips',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
        Wrap(alignment: WrapAlignment.center, spacing: 8,
          children: [for (var seat = 0; seat < players; seat++)
            Chip(label: Text('P${seat + 1}: ${game.chips[seat]}'))]),
        const SizedBox(height: 16),
        if (game.dice.isNotEmpty) Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            for (var i = 0; i < 3; i++)
              Column(mainAxisSize: MainAxisSize.min, children: [
                DieFace(game.dice[i], size: 54,
                  held: game.held.contains(i),
                  onTap: canAct && game.rollsUsed < game.rollLimit
                      ? () => setState(() { game.hold(i); save(); })
                      : null),
                Text(game.held.contains(i) ? 'Held' : 'Tap to hold'),
              ]),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: canAct && game.rollsUsed < game.rollLimit
                  ? roll : null,
              icon: const Icon(Icons.casino),
              label: Text(game.rollsUsed == 0 ? 'Roll dice' : 'Reroll'),
            ),
            OutlinedButton(
              onPressed: canAct && game.rollsUsed > 0 ? stop : null,
              child: const Text('Keep result / next player'),
            ),
          ],
        ),
        if (game.finished)
          FilledButton(onPressed: newGame, child: const Text('Play again')),
      ],
    );
  }
}
