import 'dart:math';

import 'package:flutter/material.dart';

import '../common/alquerque_board.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'alquerque_engine.dart';

class AlquerqueScreen extends StatefulWidget {
  const AlquerqueScreen({super.key});
  @override
  State<AlquerqueScreen> createState() => _AlquerqueScreenState();
}

class _AlquerqueScreenState extends State<AlquerqueScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  AlquerqueState game = AlquerqueState();
  int? from;
  bool thinking = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        thinking = false;
        from = null;
        game = AlquerqueState();
      });

  Future<void> _computer() async {
    if (!vsComputer || game.turn != 2 || game.result != 0) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || token != generation) return;
    setState(() {
      game.apply(alquerqueAi(game, level.index, rng));
      thinking = false;
    });
  }

  void _tap(int i) {
    if (thinking || game.result != 0 || (vsComputer && game.turn == 2)) return;
    final moves = game.moves();
    setState(() {
      if (from != null) {
        final m = moves.where((m) => m.from == from && m.to == i).toList();
        if (m.isNotEmpty) {
          game.apply(m.first);
          from = null;
          return;
        }
      }
      from = moves.any((m) => m.from == i) ? i : null;
    });
    _computer();
  }

  void _drag(int source, int destination) {
    if (thinking || game.result != 0 || (vsComputer && game.turn == 2)) return;
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
    String name(int p) => p == 1 ? (vsComputer ? 'You (white)' : 'White') : (vsComputer ? 'Computer' : 'Black');
    final status = r == 3
        ? 'Draw'
        : r != 0
            ? '${name(r)} ${vsComputer && r == 1 ? 'win' : 'wins'}!'
            : thinking
                ? 'Computer is thinking…'
                : '${name(game.turn)} to move${game.moves().first.captured.isNotEmpty ? ' — capture is compulsory' : ''}';
    final moves = r == 0 ? game.moves() : <AlqMove>[];
    final targets = from == null ? <int>{} : {for (final m in moves) if (m.from == from) m.to};
    final movable = {for (final m in moves) m.from};
    return GameScaffold(
      gameId: 'alquerque',
      completed: r == 1 || (!vsComputer && r == 2),
      title: 'Alquerque',
      onNewGame: _newGame,
      rules: 'Each side has twelve pieces. On your turn move one piece along '
          'a line to the next empty point, forwards or sideways but never '
          'backwards. If you can jump an adjacent enemy piece to the empty '
          'point straight behind it, you must; jumps can chain in any '
          'direction. Capture all enemy pieces or block them to win. '
          'CONTROLS: Tap the piece then its highlighted target, or drag it.',
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
        StatusBanner(status, highlight: r != 0),
        Text('White ${game.count(1)} · Black ${game.count(2)}', textAlign: TextAlign.center),
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
                              width: c * (targets.contains(i) ? .35 : .15),
                              height: c * (targets.contains(i) ? .35 : .15),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: targets.contains(i) ? colors.primary : colors.onSurface.withValues(alpha: .5)),
                            )
                          : Container(
                              width: c * .68,
                              height: c * .68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: game.cells[i] == 1 ? const Color(0xFFF5F0E6) : const Color(0xFF37474F),
                                border: Border.all(
                                  color: from == i
                                      ? colors.primary
                                      : movable.contains(i) && !thinking
                                          ? colors.tertiary
                                          : Colors.black54,
                                  width: from == i || movable.contains(i) ? 3.5 : 1.5,
                                ),
                              ),
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
