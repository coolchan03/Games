import 'dart:math';

import 'package:flutter/material.dart';

import '../common/alquerque_board.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'bagh_chal_engine.dart';

class BaghChalScreen extends StatefulWidget {
  const BaghChalScreen({super.key});
  @override
  State<BaghChalScreen> createState() => _BaghChalScreenState();
}

class _BaghChalScreenState extends State<BaghChalScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  int humanSide = 1; // 1 goats, 2 tigers
  BaghState game = BaghState();
  int? from;
  bool thinking = false;
  int generation = 0;

  void _newGame() {
    setState(() {
      generation++;
      thinking = false;
      from = null;
      game = BaghState();
    });
    _computer();
  }

  Future<void> _computer() async {
    if (!vsComputer || game.turn == humanSide || game.result != 0) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || token != generation) return;
    setState(() {
      game.apply(baghAi(game, level.index, rng));
      thinking = false;
    });
  }

  void _tap(int i) {
    if (thinking || game.result != 0 || (vsComputer && game.turn != humanSide)) return;
    final moves = game.moves();
    setState(() {
      final placing = moves.where((m) => m.from == null && m.to == i).toList();
      if (placing.isNotEmpty) {
        game.apply(placing.first);
        from = null;
      } else if (from != null && moves.any((m) => m.from == from && m.to == i)) {
        game.apply(moves.firstWhere((m) => m.from == from && m.to == i));
        from = null;
      } else if (game.cells[i] == game.turn) {
        from = i;
      } else {
        from = null;
      }
    });
    _computer();
  }

  void _drag(int source, int destination) {
    if (thinking || game.result != 0 ||
        (vsComputer && game.turn != humanSide)) return;
    final options = game.moves().where(
        (move) => move.from == source && move.to == destination).toList();
    if (options.isEmpty) return;
    setState(() {
      game.apply(options.first);
      from = null;
    });
    _computer();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = game.result;
    String side(int p) => p == 1 ? 'Goats' : 'Tigers';
    final status = r == 3
        ? 'Draw — no capture for a long time'
        : r != 0
            ? '${side(r)} win!${vsComputer ? (r == humanSide ? ' Well played.' : '') : ''}'
            : thinking
                ? 'Computer is thinking…'
                : '${side(game.turn)} to move${game.turn == 1 && game.goatsToPlace > 0 ? ' — place a goat (${game.goatsToPlace} left)' : ''}';
    final targets = from == null ? <int>{} : {for (final m in game.moves()) if (m.from == from) m.to};
    return GameScaffold(
      gameId: 'bagh_chal',
      completed: r != 0 && r != 3 && (!vsComputer || r == humanSide),
      title: 'Bagh Chal',
      onNewGame: _newGame,
      rules: 'Four tigers start in the corners; twenty goats wait off the '
          'board. Goats move first, placing one goat per turn on an empty '
          'point. Once all are placed, goats move one step along a line. '
          'Tigers move one step or jump over a single adjacent goat to an '
          'empty point straight beyond it, capturing it. Tigers win by '
          'capturing five goats; goats win by trapping every tiger. '
          'CONTROLS: Tap empty points to place goats. Tap source and target '
          'or drag a piece to move it.',
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
        if (vsComputer) ...[
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Play goats')),
              ButtonSegment(value: 2, label: Text('Play tigers')),
            ],
            selected: {humanSide},
            onSelectionChanged: (s) {
              humanSide = s.first;
              _newGame();
            },
          ),
        ],
        StatusBanner(status, highlight: r != 0),
        Text('Goats captured: ${game.captured}/5 · goats to place: ${game.goatsToPlace}', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        LandscapeBoard(child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final c = box.maxWidth / 5;
            return GridBoardTouchArea(
              columns: 5,
              onTapCell: _tap,
              onDragCell: _drag,
              onDragStartCell: _tap,
              child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: AlquerqueBoardPainter(colors.onSurface.withValues(alpha: .5)))),
              for (var i = 0; i < 25; i++)
                Positioned(
                  left: (i % 5) * c,
                  top: (i ~/ 5) * c,
                  width: c,
                  height: c,
                  child: Semantics(
                    button: true,
                    label: 'Row ${i ~/ 5 + 1}, column ${i % 5 + 1}',
                    onTap: () => _tap(i),
                    child: Center(
                      child: game.cells[i] == 0
                          ? Container(
                              width: c * (targets.contains(i) ? .35 : .18),
                              height: c * (targets.contains(i) ? .35 : .18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: targets.contains(i) ? colors.primary : colors.onSurface.withValues(alpha: .5),
                              ),
                            )
                          : Container(
                              width: c * .72,
                              height: c * .72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: game.cells[i] == 2 ? const Color(0xFFFF8F00) : const Color(0xFFEEEEEE),
                                border: Border.all(color: from == i ? colors.primary : Colors.black54, width: from == i ? 4 : 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Icon(game.cells[i] == 2 ? Icons.pets : Icons.cruelty_free,
                                  size: c * .4, color: Colors.black87),
                            ),
                    ),
                  ),
                ),
            ]));
          }),
        )),
      ],
    );
  }
}
