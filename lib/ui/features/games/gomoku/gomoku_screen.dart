import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'gomoku_engine.dart';

class GomokuScreen extends StatefulWidget {
  const GomokuScreen({super.key});
  @override
  State<GomokuScreen> createState() => _GomokuScreenState();
}

class _GomokuScreenState extends State<GomokuScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  GomokuGame game = GomokuGame();

  void _newGame() => setState(() => game = GomokuGame());

  void _tap(int i) {
    if (game.over || (vsComputer && game.turn == 2)) return;
    setState(() {
      if (!game.play(i)) return;
      if (vsComputer && !game.over) game.play(game.aiMove(level.index, rng));
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = game.size;
    final status = game.winner != 0
        ? (vsComputer ? (game.winner == 1 ? 'Five in a row — you win!' : 'Computer wins') : '${game.winner == 1 ? 'Black' : 'White'} wins!')
        : game.full
            ? 'Draw — board full'
            : '${game.turn == 1 ? 'Black' : 'White'} to play';
    return GameScaffold(
      gameId: 'gomoku',
      completed: game.winner == 1 || (!vsComputer && game.over),
      title: 'Gomoku',
      onNewGame: _newGame,
      rules: 'Players take turns placing stones on the intersections. Black '
          'moves first. The first to get five (or more) stones in an unbroken '
          'line — across, down or diagonally — wins.',
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
        StatusBanner(status, highlight: game.over),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: const Color(0xFFDCB35C),
            child: LayoutBuilder(builder: (context, box) {
              final cell = box.maxWidth / n;
              return Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _Grid(n))),
                for (var i = 0; i < n * n; i++)
                  Positioned(
                    left: (i % n) * cell,
                    top: (i ~/ n) * cell,
                    width: cell,
                    height: cell,
                    child: GestureDetector(
                      onTap: () => _tap(i),
                      behavior: HitTestBehavior.opaque,
                      child: game.board[i] == 0
                          ? null
                          : Disc(
                              color: game.board[i] == 1 ? Colors.black : Colors.white,
                              size: .86,
                              label: game.winLine.contains(i)
                                  ? '★'
                                  : game.history.isNotEmpty && game.history.last == i
                                      ? '•'
                                      : null,
                            ),
                    ),
                  ),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: game.history.isEmpty
              ? null
              : () => setState(() {
                    game.undo();
                    if (vsComputer && game.turn == 2) game.undo();
                  }),
          icon: const Icon(Icons.undo),
          label: const Text('Undo'),
        ),
      ],
    );
  }
}

class _Grid extends CustomPainter {
  _Grid(this.n);
  final int n;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final p = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final o = (i + .5) * c;
      canvas.drawLine(Offset(c / 2, o), Offset(size.width - c / 2, o), p);
      canvas.drawLine(Offset(o, c / 2), Offset(o, size.height - c / 2), p);
    }
  }

  @override
  bool shouldRepaint(_Grid old) => old.n != n;
}
