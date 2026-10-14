import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'battleship_engine.dart';

class BattleshipScreen extends StatefulWidget {
  const BattleshipScreen({super.key});
  @override
  State<BattleshipScreen> createState() => _BattleshipScreenState();
}

class _BattleshipScreenState extends State<BattleshipScreen> {
  final rng = Random();
  AiLevel level = AiLevel.medium;
  late Ocean mine, theirs;
  late Gunner gunner;
  String log = 'Fire at the enemy waters';
  bool busy = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    generation++;
    mine = Ocean(rng);
    theirs = Ocean(rng);
    gunner = Gunner(level.index, rng);
    log = 'Fire at the enemy waters';
    busy = false;
  }

  bool get over => mine.defeated || theirs.defeated;

  Future<void> _fire(int cell) async {
    if (busy || over || theirs.shots.contains(cell)) return;
    final token = generation;
    setState(() {
      final r = theirs.fire(cell);
      log = r == 'miss' ? 'You missed.' : r == 'hit' ? 'You hit something!' : 'You sank their $r!';
      busy = true;
    });
    if (over) {
      setState(() => busy = false);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || token != generation) return;
    setState(() {
      final target = gunner.pick(mine);
      final r = mine.fire(target);
      final where = '${String.fromCharCode(65 + target ~/ 10)}${target % 10 + 1}';
      log += '\nComputer fires at $where: ${r == 'miss' ? 'miss' : r == 'hit' ? 'hit!' : 'sank your $r!'}';
      busy = false;
    });
  }

  Widget _grid(Ocean ocean, {required bool enemy}) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemCount: 100,
        itemBuilder: (context, i) {
          final ship = ocean.shipAt(i);
          final shot = ocean.shots.contains(i);
          final reveal = !enemy || over;
          Color bg = const Color(0xFF90CAF9);
          if (ship != null && reveal) bg = const Color(0xFF78909C);
          if (shot && ship != null) bg = ocean.sunk(ship) ? const Color(0xFF8E2424) : const Color(0xFFE53935);
          return GestureDetector(
            onTap: enemy ? () => _fire(i) : null,
            child: Container(
              margin: const EdgeInsets.all(.5),
              color: bg,
              alignment: Alignment.center,
              child: shot
                  ? Icon(ship == null ? Icons.circle : Icons.close,
                      size: ship == null ? 6 : 14, color: ship == null ? colors.onSurface : Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = mine.defeated
        ? 'The computer sank your fleet.'
        : theirs.defeated
            ? 'Victory! You sank the whole fleet in ${theirs.shots.length} shots.'
            : log;
    final left = theirs.ships.where((s) => !theirs.sunk(s)).map((s) => s.name).join(', ');
    return GameScaffold(
      gameId: 'battleship',
      completed: theirs.defeated,
      title: 'Battleship',
      onNewGame: () => setState(_newGame),
      rules: 'Both fleets — Carrier (5), Battleship (4), Cruiser (3), '
          'Submarine (3) and Destroyer (2) — are hidden on 10×10 grids. Take '
          'turns firing at a square. Red marks a hit, dark red a sunk ship. '
          'Sink all five enemy ships before the computer sinks yours.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() {
            level = s.first;
            _newGame();
          }),
        ),
        StatusBanner(status, highlight: over),
        Text('Enemy waters — still afloat: ${left.isEmpty ? 'none' : left}', textAlign: TextAlign.center),
        const SizedBox(height: 4),
        _grid(theirs, enemy: true),
        const SizedBox(height: 12),
        const Text('Your fleet', textAlign: TextAlign.center),
        const SizedBox(height: 4),
        FractionallySizedBox(widthFactor: .6, child: _grid(mine, enemy: false)),
      ],
    );
  }
}
