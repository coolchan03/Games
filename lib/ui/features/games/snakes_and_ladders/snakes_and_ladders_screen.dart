import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';

/// Classic Snakes and Ladders layout (squares 1-100).
const ladders = {1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100};
const snakes = {16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78};

class SnakesGame {
  SnakesGame(this.players, {Random? random}) : rng = random ?? Random();
  final int players;
  final Random rng;
  late final List<int> pos = List.filled(players, 0);
  int turn = 0;
  int? lastRoll;
  int? winner;
  String message = '';

  void roll([int? fixed]) {
    if (winner != null) return;
    final d = fixed ?? rng.nextInt(6) + 1;
    lastRoll = d;
    var p = pos[turn] + d;
    if (p > 100) {
      message = 'Player ${turn + 1} needs exactly ${100 - pos[turn]}';
      p = pos[turn];
    } else if (ladders.containsKey(p)) {
      message = 'Player ${turn + 1} climbs a ladder from $p to ${ladders[p]}!';
      p = ladders[p]!;
    } else if (snakes.containsKey(p)) {
      message = 'Player ${turn + 1} slides down a snake from $p to ${snakes[p]}';
      p = snakes[p]!;
    } else {
      message = 'Player ${turn + 1} moves to $p';
    }
    pos[turn] = p;
    if (p == 100) {
      winner = turn;
      return;
    }
    if (d != 6) turn = (turn + 1) % players;
  }
}

const _tokenColors = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFDD835)];

class SnakesAndLaddersScreen extends StatefulWidget {
  const SnakesAndLaddersScreen({super.key});
  @override
  State<SnakesAndLaddersScreen> createState() => _SnakesAndLaddersScreenState();
}

class _SnakesAndLaddersScreenState extends State<SnakesAndLaddersScreen> {
  int players = 2;
  bool vsComputer = true;
  late SnakesGame game = SnakesGame(players);
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        game = SnakesGame(players);
      });

  Future<void> _roll() async {
    if (busy) return;
    final token = generation;
    setState(game.roll);
    busy = true;
    while (mounted && token == generation && vsComputer && game.winner == null && game.turn != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || token != generation) return;
      setState(game.roll);
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  static Offset cellOf(int square) {
    final i = square - 1;
    final row = i ~/ 10;
    final col = row.isEven ? i % 10 : 9 - i % 10;
    return Offset(col.toDouble(), (9 - row).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    String name(int p) => vsComputer ? (p == 0 ? 'You' : 'Computer $p') : 'Player ${p + 1}';
    final status = game.winner != null
        ? '${name(game.winner!)} reached 100!'
        : '${game.message.isEmpty ? '' : '${game.message}\n'}${name(game.turn)} to roll';
    return GameScaffold(
      title: 'Snakes and Ladders',
      onNewGame: _newGame,
      rules: 'Roll the die and move your token. Land at the foot of a ladder '
          'to climb it; land on a snake\'s head to slide down. Rolling a 6 '
          'gives another roll. You need the exact number to finish on 100.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: AiLevel.easy,
          showLevel: false,
          onChanged: (v, _) {
            vsComputer = v;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4 players')),
          ],
          selected: {players},
          onSelectionChanged: (s) {
            players = s.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: game.winner != null),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final cell = box.maxWidth / 10;
            return Stack(children: [
              for (var sq = 1; sq <= 100; sq++)
                Positioned(
                  left: cellOf(sq).dx * cell,
                  top: cellOf(sq).dy * cell,
                  width: cell,
                  height: cell,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (cellOf(sq).dx + cellOf(sq).dy).toInt().isEven
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFFFE0B2),
                      border: Border.all(color: Colors.black12, width: .5),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Text('$sq', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                  ),
                ),
              Positioned.fill(child: CustomPaint(painter: _SnakesPainter(cell))),
              for (var p = 0; p < players; p++)
                if (game.pos[p] > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    left: (cellOf(game.pos[p]).dx + .1 + (p % 2) * .4) * cell,
                    top: (cellOf(game.pos[p]).dy + .1 + (p ~/ 2) * .4) * cell,
                    width: cell * .42,
                    height: cell * .42,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _tokenColors[p],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
            ]);
          }),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var p = 0; p < players; p++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Chip(
                avatar: CircleAvatar(backgroundColor: _tokenColors[p]),
                label: Text('${game.pos[p]}'),
              ),
            ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (game.lastRoll != null) DieFace(game.lastRoll!, size: 44),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: busy || game.winner != null ? null : _roll,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Roll'),
          ),
        ]),
      ],
    );
  }
}

class _SnakesPainter extends CustomPainter {
  _SnakesPainter(this.cell);
  final double cell;

  Offset _c(int sq) {
    final o = _SnakesAndLaddersScreenState.cellOf(sq);
    return Offset((o.dx + .5) * cell, (o.dy + .5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3;
    ladders.forEach((a, b) {
      final p = _c(a), q = _c(b);
      final d = q - p;
      final n = Offset(-d.dy, d.dx) / d.distance * cell * .15;
      canvas.drawLine(p + n, q + n, rail);
      canvas.drawLine(p - n, q - n, rail);
      final rungs = (d.distance / (cell * .4)).floor();
      for (var k = 1; k < rungs; k++) {
        final m = p + d * (k / rungs);
        canvas.drawLine(m + n, m - n, rail..strokeWidth = 2);
      }
      rail.strokeWidth = 3;
    });
    final body = Paint()
      ..color = const Color(0xCC2E7D32)
      ..strokeWidth = cell * .18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    snakes.forEach((a, b) {
      final p = _c(a), q = _c(b);
      final d = q - p;
      final n = Offset(-d.dy, d.dx) / d.distance * cell * .5;
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..cubicTo((p + d * .33 + n).dx, (p + d * .33 + n).dy, (p + d * .66 - n).dx,
            (p + d * .66 - n).dy, q.dx, q.dy);
      canvas.drawPath(path, body);
      canvas.drawCircle(p, cell * .16, Paint()..color = const Color(0xFF1B5E20));
    });
  }

  @override
  bool shouldRepaint(_SnakesPainter old) => old.cell != cell;
}
