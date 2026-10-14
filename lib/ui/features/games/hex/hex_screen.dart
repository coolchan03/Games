import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'hex_engine.dart';

const _red = Color(0xFFE53935), _blue = Color(0xFF1E88E5);

class HexScreen extends StatefulWidget {
  const HexScreen({super.key});
  @override
  State<HexScreen> createState() => _HexScreenState();
}

class _HexScreenState extends State<HexScreen> {
  final rng = Random();
  int size = 9;
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late HexGame game = HexGame(n: size);
  bool thinking = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        thinking = false;
        game = HexGame(n: size);
      });

  Future<void> _tap(int i) async {
    if (thinking || (vsComputer && game.turn == 2) || !game.play(i)) return;
    setState(() {});
    if (!vsComputer || game.winner != 0) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted || token != generation) return;
    final playouts = [60, 400, 1500][level.index];
    setState(() {
      game.play(game.aiMove(playouts, rng));
      thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = game.n;
    final path = game.winningPath();
    final status = game.winner != 0
        ? (vsComputer ? (game.winner == 1 ? 'You connected top to bottom — you win!' : 'Computer connects left to right') : '${game.winner == 1 ? 'Red' : 'Blue'} wins!')
        : thinking
            ? 'Computer is thinking…'
            : '${game.turn == 1 ? 'Red (top ↔ bottom)' : 'Blue (left ↔ right)'} to play';
    return GameScaffold(
      title: 'Hex',
      onNewGame: _newGame,
      rules: 'Take turns placing a stone on any empty hexagon. Red tries to '
          'build an unbroken chain linking the top and bottom edges; Blue '
          'links the left and right edges. A game of Hex can never end in a '
          'draw. Against the computer you play Red and move first.',
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
          segments: [for (final s in const [7, 9, 11]) ButtonSegment(value: s, label: Text('$s×$s'))],
          selected: {size},
          onSelectionChanged: (s) {
            size = s.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: game.winner != 0),
        LayoutBuilder(builder: (context, box) {
          // Rhombus: row r is shifted right by r/2 cells.
          final cellW = box.maxWidth / (n + (n - 1) / 2 + 1);
          final r = cellW / sqrt(3);
          final rowH = r * 1.5;
          final height = rowH * (n - 1) + 2 * r + cellW;
          final colors = Theme.of(context).colorScheme;
          return SizedBox(
            height: height,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _Edges(n, cellW, r, rowH))),
              for (var i = 0; i < n * n; i++)
                Positioned(
                  left: cellW / 2 + (i % n + (i ~/ n) / 2) * cellW,
                  top: cellW / 2 + (i ~/ n) * rowH,
                  width: cellW,
                  height: 2 * r,
                  child: GestureDetector(
                    onTap: () => _tap(i),
                    child: CustomPaint(
                      painter: _HexCell(
                        game.cells[i] == 0 ? colors.surfaceContainerHighest : game.cells[i] == 1 ? _red : _blue,
                        path.contains(i),
                        game.history.isNotEmpty && game.history.last == i,
                      ),
                    ),
                  ),
                ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: game.history.isEmpty || thinking
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

Path _hexPath(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..lineTo(w, h * .25)
    ..lineTo(w, h * .75)
    ..lineTo(w / 2, h)
    ..lineTo(0, h * .75)
    ..lineTo(0, h * .25)
    ..close();
}

class _HexCell extends CustomPainter {
  _HexCell(this.fill, this.win, this.last);
  final Color fill;
  final bool win, last;
  @override
  void paint(Canvas canvas, Size size) {
    final p = _hexPath(size);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = win ? Colors.amber : Colors.black26
          ..strokeWidth = win ? 3 : 1);
    if (last) {
      canvas.drawCircle(size.center(Offset.zero), size.width * .12, Paint()..color = Colors.white70);
    }
  }

  @override
  bool shouldRepaint(_HexCell old) => old.fill != fill || old.win != win || old.last != last;
}

class _Edges extends CustomPainter {
  _Edges(this.n, this.w, this.r, this.rowH);
  final int n;
  final double w, r, rowH;
  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..color = _red
      ..strokeWidth = 6;
    final blue = Paint()
      ..color = _blue
      ..strokeWidth = 6;
    final top = w / 2 + r * .25;
    final bottom = w / 2 + (n - 1) * rowH + 2 * r * .75;
    final x0 = w / 2, x1 = w / 2 + n * w;
    final shift = (n - 1) / 2 * w;
    canvas.drawLine(Offset(x0, top - 4), Offset(x1, top - 4), red);
    canvas.drawLine(Offset(x0 + shift, bottom + 4), Offset(x1 + shift, bottom + 4), red);
    canvas.drawLine(Offset(x0 - 4, top), Offset(x0 + shift - 4, bottom), blue);
    canvas.drawLine(Offset(x1 + 4, top), Offset(x1 + shift + 4, bottom), blue);
  }

  @override
  bool shouldRepaint(_Edges old) => old.n != n || old.w != w;
}
