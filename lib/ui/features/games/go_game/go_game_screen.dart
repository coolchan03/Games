import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'go_engine.dart';

class GoGameScreen extends StatefulWidget {
  const GoGameScreen({super.key});
  @override
  State<GoGameScreen> createState() => _GoGameScreenState();
}

class _GoGameScreenState extends State<GoGameScreen> {
  final rng = Random();
  int size = 9;
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late GoBoard board = GoBoard(size);
  final List<GoBoard> history = [];
  bool thinking = false;
  int generation = 0;
  int? last;

  double get komi => 6.5;

  void _newGame() => setState(() {
        generation++;
        thinking = false;
        board = GoBoard(size);
        history.clear();
        last = null;
      });

  Future<void> _computer() async {
    if (!vsComputer || board.turn != 2 || board.over) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted || token != generation) return;
    final playouts = [150, 600, 2000][level.index];
    final move = board.aiMove(playouts, rng, komi, timeMs: [400, 1000, 2000][level.index]);
    setState(() {
      history.add(board.copy());
      if (move < 0) {
        board.pass();
        last = null;
      } else {
        board.play(move);
        last = move;
      }
      thinking = false;
    });
  }

  void _tap(int i) {
    if (thinking || board.over || (vsComputer && board.turn == 2)) return;
    final before = board.copy();
    if (!board.play(i)) return;
    setState(() {
      history.add(before);
      last = i;
    });
    _computer();
  }

  void _pass() {
    if (thinking || board.over) return;
    setState(() {
      history.add(board.copy());
      board.pass();
      last = null;
    });
    _computer();
  }

  @override
  Widget build(BuildContext context) {
    final n = board.n;
    final (b, w) = board.score(komi);
    String status;
    if (board.over) {
      status = 'Game over — Black ${b.toStringAsFixed(0)}, White ${w.toStringAsFixed(1)} (komi $komi). '
          '${b > w ? 'Black' : 'White'} wins${vsComputer ? (b > w ? ' — that\'s you!' : '') : ''}';
    } else if (thinking) {
      status = 'Computer is thinking…';
    } else {
      status = '${board.turn == 1 ? 'Black' : 'White'} to play${board.passes == 1 ? ' (opponent passed)' : ''}';
    }
    return GameScaffold(
      gameId: 'go_game',
      completed: board.over && (!vsComputer || b > w),
      title: 'Go',
      onNewGame: _newGame,
      rules: 'Players take turns placing stones on the intersections; Black '
          'plays first. A group of stones with no empty neighbouring point '
          '(liberty) is captured. You may not play a move that leaves your '
          'own group without liberties unless it captures, nor immediately '
          'retake a single stone in a ko. The game ends after two passes in '
          'a row. Score = your stones + empty areas only you surround; White '
          'gets 6.5 komi. Remove dead stones by capturing them before '
          'passing. Against the computer you play Black.',
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
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 9, label: Text('9×9')),
            ButtonSegment(value: 13, label: Text('13×13')),
          ],
          selected: {size},
          onSelectionChanged: (s) {
            size = s.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: board.over),
        Text('Captures — Black ${board.captures[0]} · White ${board.captures[1]}', textAlign: TextAlign.center),
        const SizedBox(height: 6),
        LandscapeBoard(child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: const Color(0xFFDCB35C),
            child: LayoutBuilder(builder: (context, box) {
              final cell = box.maxWidth / n;
              return Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _GoGrid(n))),
                for (var i = 0; i < n * n; i++)
                  Positioned(
                    left: (i % n) * cell,
                    top: (i ~/ n) * cell,
                    width: cell,
                    height: cell,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _tap(i),
                      child: board.cells[i] == 0
                          ? null
                          : Disc(
                              color: board.cells[i] == 1 ? Colors.black : Colors.white,
                              size: .92,
                              label: last == i ? '●' : null,
                            ),
                    ),
                  ),
              ]);
            }),
          ),
        )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(onPressed: board.over || thinking ? null : _pass, child: const Text('Pass')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: history.isEmpty || thinking
                  ? null
                  : () => setState(() {
                        board = history.removeLast();
                        if (vsComputer && board.turn == 2 && history.isNotEmpty) board = history.removeLast();
                        last = null;
                      }),
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
          ),
        ]),
      ],
    );
  }
}

class _GoGrid extends CustomPainter {
  _GoGrid(this.n);
  final int n;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final p = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final o = (i + .5) * c;
      canvas.drawLine(Offset(c / 2, o), Offset(size.width - c / 2, o), p);
      canvas.drawLine(Offset(o, c / 2), Offset(o, size.height - c / 2), p);
    }
    final stars = n == 9 ? [2, 4, 6] : [3, 6, 9];
    for (final x in stars) {
      for (final y in stars) {
        if (n == 9 && (x == 4) != (y == 4)) continue;
        canvas.drawCircle(Offset((x + .5) * c, (y + .5) * c), c * .1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GoGrid old) => old.n != n;
}
