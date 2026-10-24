import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/sowing_board.dart';
import 'oware_engine.dart';

class OwareScreen extends StatefulWidget {
  const OwareScreen({super.key});
  @override
  State<OwareScreen> createState() => _OwareScreenState();
}

class _OwareScreenState extends State<OwareScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  OwareState game = OwareState();
  bool thinking = false;
  int generation = 0;
  int? last;

  void _newGame() => setState(() {
        generation++;
        thinking = false;
        last = null;
        game = OwareState();
      });

  Future<void> _computer() async {
    if (!vsComputer || game.turn != 1 || game.result != -1) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || token != generation) return;
    final m = owareAi(game, level.index, rng);
    setState(() {
      game.play(m);
      last = m;
      thinking = false;
    });
  }

  void _tap(int pit) {
    if (thinking || game.result != -1 || (vsComputer && game.turn == 1)) return;
    if (!game.legalMoves().contains(pit)) return;
    setState(() {
      game.play(pit);
      last = pit;
    });
    _computer();
  }

  Widget _pit(int i) {
    final legal = game.result == -1 &&
        game.legalMoves().contains(i) &&
        !(vsComputer && game.turn == 1) &&
        !thinking;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SowingPit(
        key: ValueKey('oware_pit_$i'),
        seeds: game.pits[i],
        seedKey: i,
        enabled: legal,
        lastMove: last == i,
        onTap: () => _tap(i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = game.result;
    final names = vsComputer ? ['You', 'Computer'] : ['South', 'North'];
    final status = r == 2
        ? 'Draw ${game.stores[0]}–${game.stores[1]}'
        : r >= 0
            ? '${names[r]} win${r == 0 && vsComputer ? '' : 's'}!'
            : thinking
                ? 'Computer is sowing…'
                : '${names[game.turn]} to sow';
    return GameScaffold(
      gameId: 'oware',
      maxWidth: 900, // a wide board: use the width on tablets
      completed: r == 0 || (!vsComputer && r == 1),
      title: 'Oware',
      onNewGame: _newGame,
      rules: 'The West African sowing game (Abapa rules). Pick one of your '
          'pits and sow its seeds one by one counter-clockwise. If the last '
          'seed lands in an opponent\'s pit making 2 or 3, capture them, and '
          'also any unbroken run of 2s and 3s just before it on their side. '
          'A move that would capture all the opponent\'s seeds captures '
          'nothing. If your opponent has no seeds you must give them some '
          'if you can. First to 25 seeds wins.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: r >= 0),
        const SizedBox(height: 8),
        SowingBoard(
          top: [for (var i = 11; i >= 6; i--) _pit(i)],
          bottom: [for (var i = 0; i < 6; i++) _pit(i)],
          leftStore:
              SeedStore(
              seeds: game.stores[1],
              label: vsComputer ? 'CPU' : 'N',
              seedKey: 21),
          rightStore:
              SeedStore(
              seeds: game.stores[0],
              label: vsComputer ? 'You' : 'S',
              seedKey: 20),
        ),
        const SizedBox(height: 4),
        Text(
            '${names[0]} (bottom row) ${game.stores[0]} · ${names[1]} ${game.stores[1]} — first to 25',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
