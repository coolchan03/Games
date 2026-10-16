import 'dart:math';

import 'package:flutter/material.dart';
import '../common/game_kit.dart';
import '../shared/game_storage.dart';
import 'dice_421_game.dart';

/// Offline charge/discharge 421: all players share this device.
class Dice421Screen extends StatefulWidget {
  const Dice421Screen({super.key});
  @override
  State<Dice421Screen> createState() => _Dice421ScreenState();
}

class _Dice421ScreenState extends State<Dice421Screen> {
  final rng = Random();
  late Dice421Game game;
  bool ready = false, thinking = false;
  int generation = 0;
  String saveStatus = 'Loading your table...';

  @override
  void initState() {
    super.initState();
    game = Dice421Game(random: rng);
    restore();
  }

  Future<void> restore() async {
    try {
      final saved = await GameStorage.load('dice_421_v1');
      if (!mounted) return;
      if (saved != null) game = Dice421Game.fromJson(saved);
      saveStatus = saved == null ? 'Local game. No account required.'
          : 'Previous game restored on this device.';
    } catch (_) {
      saveStatus = 'Saved game could not be restored. Starting fresh.';
    }
    if (!mounted) return;
    setState(() => ready = true);
    runComputer();
  }

  Future<void> persist() async {
    try {
      await GameStorage.save('dice_421_v1', game.toJson());
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Could not save this round');
    }
  }

  bool get myTurn => ready && !thinking &&
      game.phase != Dice421Phase.finished &&
      (!game.computer || game.current == 0);

  void fresh(int players, bool computer) {
    generation++;
    setState(() {
      game = Dice421Game(players: players, computer: computer, random: rng);
      thinking = false;
    });
    persist();
  }

  void rollDice() {
    if (!myTurn) return;
    if (game.roll()) {
      setState(() {});
      persist();
    }
  }

  void hold(int index) {
    if (!myTurn) return;
    if (game.toggleHeld(index)) {
      setState(() {});
      persist();
    }
  }

  void finishTurn() {
    if (!myTurn) return;
    if (game.stand()) {
      setState(() {});
      persist();
      runComputer();
    }
  }

  Future<void> runComputer() async {
    if (!mounted || !ready || !game.computer || thinking ||
        game.current != 1 || game.phase == Dice421Phase.finished) return;
    final token = ++generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || token != generation) return;
    setState(() {
      game.playComputerTurn();
      thinking = false;
    });
    await persist();
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = game.phase;
    final currentHand = game.throwsTaken == 0
        ? null : Dice421Hand(game.dice);
    final complete = phase == Dice421Phase.finished;
    return GameScaffold(
      title: '421',
      gameId: 'dice_421',
      completed: complete && game.winner == 0,
      onNewGame: () => fresh(game.players, game.computer),
      rules: '421 (French dice game), played on one device with three dice '
          'and 21 counters.\n\n'
          'CHARGE: Each player throws once. The player with the weakest '
          'combination takes counters from the bank according to the '
          'strongest hand (421 = 10; 111 = 7; two aces plus another die, '
          'or three of a kind, score 2-6; a straight = 2; otherwise 1). '
          'The lowest hand 2-2-1, called Nénette, takes 2. '
          'Once the bank is empty, discharge begins.\n\n'
          'DISCHARGE: Up to three throws, and you may tap a die to hold it '
          'before a reroll. The first player sets the round throw limit '
          'for everyone else. The strongest player gives counters to '
          'the weakest. The first player to clear their counters wins. '
          'Tied top or bottom hands replay without transfer.\n\n'
          'Same-device multiplayer: pass the phone after ending your turn. '
          'No internet connection, money or accounts are needed.',
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: game.computer ? 'bot' : '${game.players}',
          items: [
            const DropdownMenuItem(
              value: 'bot', child: Text('You vs computer')),
            for (final n in [2, 3, 4])
              DropdownMenuItem(
                  value: '$n', child: Text('$n players - same device')),
          ],
          onChanged: !ready || thinking ? null : (v) {
            if (v != null) {
              fresh(v == 'bot' ? 2 : int.parse(v), v == 'bot');
            }
          },
        ),
        const SizedBox(height: 8),
        StatusBanner(complete
            ? 'Player ${game.winner! + 1} wins!'
            : '${phase == Dice421Phase.charge ? 'CHARGE' : 'DISCHARGE'}'
              ' - Player ${game.current + 1}${thinking ? ' (computer)' : ''}',
          highlight: complete),
        Text(saveStatus,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Bank: ${game.bank} counters · Round ${game.rounds + 1}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8, runSpacing: 8,
          children: [
            for (var seat = 0; seat < game.players; seat++)
              Chip(
                avatar: Icon(seat == game.current && !complete
                    ? Icons.person : Icons.radio_button_unchecked),
                label: Text('P${seat + 1}: ${game.tokens[seat]}'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(game.message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (!complete) ...[
          Text(
            thinking
                ? 'Computer rolling...'
                : phase == Dice421Phase.charge
                    ? 'Roll once, then end your turn. Pass the phone.'
                    : 'Roll up to ${game.allowedThrows} times. Tap dice to hold.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (game.throwsTaken > 0)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  DieFace(
                    game.dice[i],
                    size: 70,
                    held: game.held[i],
                    onTap: myTurn && game.throwsTaken < game.allowedThrows
                      ? () => hold(i) : null,
                  ),
              ],
            ),
          if (currentHand != null)
            Text('Hand: ${currentHand.label} · ${currentHand.chips} counters',
                textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: myTurn && game.throwsTaken < game.allowedThrows
                    ? rollDice : null,
                icon: const Icon(Icons.casino),
                label: Text(game.throwsTaken == 0 ? 'Roll dice' : 'Reroll free dice'),
              ),
              OutlinedButton.icon(
                onPressed: myTurn && game.throwsTaken > 0 ? finishTurn : null,
                icon: const Icon(Icons.check),
                label: const Text('End turn'),
              ),
            ],
          ),
        ] else
          FilledButton(
            onPressed: () => fresh(game.players, game.computer),
            child: const Text('Play again'),
          ),
      ],
    );
  }
}
