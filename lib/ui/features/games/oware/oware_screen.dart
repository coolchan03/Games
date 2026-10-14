import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
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
    final colors = Theme.of(context).colorScheme;
    final legal = game.result == -1 && game.legalMoves().contains(i) && !(vsComputer && game.turn == 1) && !thinking;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () => _tap(i),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8D6E63),
              border: Border.all(
                color: legal ? colors.primary : last == i ? Colors.amber : Colors.black26,
                width: legal || last == i ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text('${game.pits[i]}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
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
        Text('${names[1]}: ${game.stores[1]}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(30)),
          child: Column(children: [
            Row(children: [for (var i = 11; i >= 6; i--) _pit(i)]),
            Row(children: [for (var i = 0; i < 6; i++) _pit(i)]),
          ]),
        ),
        const SizedBox(height: 6),
        Text('${names[0]}: ${game.stores[0]}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
