import 'dart:math';
import 'package:flutter/material.dart';

import '../common/game_kit.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});
  @override
  State<TicTacToeScreen> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToeScreen> {
  final random = Random();
  List<int> board = List.filled(9, 0);
  bool vsAi = true;
  int difficulty = 1, turn = 1;

  /// The completed line, if any.
  List<int>? get winningLine {
    for (final line in const [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ]) {
      final p = board[line[0]];
      if (p != 0 && line.every((i) => board[i] == p)) return line;
    }
    return null;
  }

  int get result {
    for (final line in const [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ]) {
      final p = board[line[0]];
      if (p != 0 && line.every((i) => board[i] == p)) return p;
    }
    return board.every((p) => p != 0) ? 3 : 0;
  }

  void reset() => setState(() {
        board = List.filled(9, 0);
        turn = 1;
      });
  int minimax(int player) {
    final r = result;
    if (r != 0)
      return r == 3
          ? 0
          : r == 2
              ? 10
              : -10;
    final options = [
      for (var i = 0; i < 9; i++)
        if (board[i] == 0) i
    ];
    var best = player == 2 ? -100 : 100;
    for (final i in options) {
      board[i] = player;
      final score = minimax(3 - player);
      board[i] = 0;
      best = player == 2 ? max(best, score) : min(best, score);
    }
    return best;
  }

  int aiMove() {
    final options = [
      for (var i = 0; i < 9; i++)
        if (board[i] == 0) i
    ];
    if (difficulty == 0) return options[random.nextInt(options.length)];
    var best = -100;
    final good = <int>[];
    for (final i in options) {
      board[i] = 2;
      final score = minimax(1);
      board[i] = 0;
      if (score > best) {
        best = score;
        good
          ..clear()
          ..add(i);
      } else if (score == best) good.add(i);
    }
    if (difficulty == 1 && random.nextDouble() < .35)
      return options[random.nextInt(options.length)];
    return good[random.nextInt(good.length)];
  }

  void play(int i) {
    if (result != 0 || board[i] != 0) return;
    setState(() {
      board[i] = turn;
      if (result == 0) {
        turn = 3 - turn;
        if (vsAi) {
          board[aiMove()] = 2;
          turn = 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final names = vsAi ? ['You (X)', 'Computer (O)'] : ['X', 'O'];
    final status = r == 3
        ? 'Draw'
        : r != 0
            ? '${names[r - 1]} win${vsAi && r == 1 ? '' : 's'}!'
            : '${names[turn - 1]} to move';
    final colors = Theme.of(context).colorScheme;
    return GameScaffold(
      gameId: 'tic_tac_toe',
      completed: vsAi ? r == 1 : r == 1 || r == 2,
      title: 'Tic-Tac-Toe',
      maxWidth: 480,
      onNewGame: reset,
      rules: 'Take turns placing X and O in the 3×3 grid. The first to get '
          'three in a row — across, down or diagonally — wins; a full grid '
          'with no line is a draw. X always starts. On Hard the computer '
          'never loses.',
      children: [
        OpponentPicker(
          vsComputer: vsAi,
          level: AiLevel.values[difficulty],
          onChanged: (v, l) => setState(() {
            vsAi = v;
            difficulty = l.index;
            board = List.filled(9, 0);
            turn = 1;
          }),
        ),
        StatusBanner(status, highlight: r != 0),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Colors.black26),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: CustomPaint(
              foregroundPainter: _WinLine(winningLine, colors.onSurface),
              painter: _Grid(colors.outline),
              child: GridView.builder(
                itemCount: 9,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (context, i) => Semantics(
                  label: 'Square ${i + 1}: '
                      '${board[i] == 0 ? 'empty' : board[i] == 1 ? 'X' : 'O'}',
                  button: board[i] == 0 && r == 0,
                  child: GestureDetector(
                    key: ValueKey('tic_tac_toe_cell_$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => play(i),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, a) =>
                            ScaleTransition(scale: a, child: child),
                        child: board[i] == 0
                            ? const SizedBox.expand()
                            : CustomPaint(
                                key: ValueKey(board[i]),
                                painter: _Mark(board[i] == 1),
                                child: const SizedBox.expand(),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Grid extends CustomPainter {
  _Grid(this.colour);
  final Color colour;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = colour
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var k = 1; k < 3; k++) {
      final x = size.width * k / 3, y = size.height * k / 3;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), p);
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), p);
    }
  }

  @override
  bool shouldRepaint(_Grid old) => old.colour != colour;
}

class _Mark extends CustomPainter {
  _Mark(this.cross);
  final bool cross;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .14
      ..color = cross ? const Color(0xFF1E88E5) : const Color(0xFFE53935);
    if (cross) {
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), p);
      canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), p);
    } else {
      canvas.drawCircle(size.center(Offset.zero), size.width * .43, p);
    }
  }

  @override
  bool shouldRepaint(_Mark old) => old.cross != cross;
}

class _WinLine extends CustomPainter {
  _WinLine(this.line, this.colour);
  final List<int>? line;
  final Color colour;
  @override
  void paint(Canvas canvas, Size size) {
    final l = line;
    if (l == null) return;
    Offset centre(int i) =>
        Offset((i % 3 + .5) * size.width / 3, (i ~/ 3 + .5) * size.height / 3);
    canvas.drawLine(
      centre(l.first),
      centre(l.last),
      Paint()
        ..color = colour.withValues(alpha: .75)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WinLine old) => old.line != line;
}
