import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'ludo_engine.dart';

const _seatColors = [Color(0xFF1AAA30), Color(0xFFFFCD1D), Color(0xFF4A5FD1), Color(0xFFF84700)];
const _seatNames = ['Green', 'Yellow', 'Blue', 'Red'];

/// Base slot (top-left cell coordinates) for piece [p] of [seat].
Offset _baseSlot(int seat, int p) {
  var c = p.isEven ? 1.5 : 3.5, r = p < 2 ? 1.5 : 3.5;
  for (var k = 0; k < seat; k++) {
    final nc = 14 - r, nr = c;
    c = nc;
    r = nr;
  }
  return Offset(c, r);
}

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});
  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  int players = 4;
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late LudoGame game;
  bool busy = false;
  int generation = 0;
  int? lastRoll;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    generation++;
    busy = false;
    lastRoll = null;
    // Human is red (bottom-left); seats are chosen so play stays clockwise.
    final seats = switch (players) {
      2 => [1, 3],
      3 => [0, 1, 3],
      _ => [0, 1, 2, 3],
    };
    game = LudoGame(
      seats: seats,
      computer: vsComputer ? {for (final s in seats) if (s != 3) s} : {},
    );
    game.current = 3;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runComputer());
  }

  bool get _computerTurn => !game.over && game.computer.contains(game.current);

  Future<void> _runComputer() async {
    if (busy || !_computerTurn) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && _computerTurn) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || token != generation) return;
      final seat = game.current;
      bool canMove = false;
      setState(() {
        canMove = game.roll();
        lastRoll = game.dice ?? lastRoll;
      });
      if (!canMove) continue;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || token != generation) return;
      setState(() => game.play(game.choose(level.index)));
      if (game.current != seat) continue;
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _roll() {
    if (busy || _computerTurn || game.dice != null) return;
    setState(() {
      final ok = game.roll();
      lastRoll = game.dice;
      if (!ok) {
        game.message ??= 'No move with that roll';
      } else if (game.legal.length == 1) {
        game.play(game.legal.first);
      }
    });
    _runComputer();
  }

  void _tapPiece(int seat, int piece) {
    if (busy || seat != game.current || game.dice == null || _computerTurn) return;
    final m = game.legal.where((m) => m.piece == piece).toList();
    if (m.isEmpty) return;
    setState(() => game.play(m.first));
    _runComputer();
  }

  @override
  Widget build(BuildContext context) {
    final cur = game.current;
    String status;
    if (game.over) {
      final order = [...game.finishOrder, ...game.seats.where((s) => !game.finishOrder.contains(s))];
      status = 'Finished: ${[for (var i = 0; i < order.length; i++) '${i + 1}. ${_seatNames[order[i]]}'].join('  ')}';
    } else if (_computerTurn || busy) {
      status = '${_seatNames[cur]} (computer) is playing…';
    } else if (game.dice == null) {
      status = '${_seatNames[cur]}${cur == 3 && vsComputer ? ' (you)' : ''}: roll the die';
    } else {
      status = '${_seatNames[cur]} rolled ${game.dice} — tap a glowing piece';
    }
    if (game.message != null && !game.over) status = '${game.message}\n$status';
    final movable = {for (final m in game.legal) m.piece};
    return GameScaffold(
      gameId: 'ludo',
      completed: game.finishOrder.isNotEmpty && (!vsComputer || game.finishOrder.first == 3),
      title: 'Ludo',
      onNewGame: () => setState(_newGame),
      rules: 'Race your four pieces around the board and into the centre. '
          'Roll a 6 to bring a piece out. Landing on an opponent sends it '
          'back to its base, except on starred safe squares and start squares. '
          'Rolling a 6, capturing, or bringing a piece home earns another '
          'roll; three 6s in a row lose the turn. You need an exact roll to '
          'reach the centre.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) => setState(() {
            vsComputer = v;
            level = l;
            _newGame();
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2 players')),
            ButtonSegment(value: 3, label: Text('3 players')),
            ButtonSegment(value: 4, label: Text('4 players')),
          ],
          selected: {players},
          onSelectionChanged: (s) => setState(() {
            players = s.first;
            _newGame();
          }),
        ),
        StatusBanner(status, highlight: game.over),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final cell = box.maxWidth / 15;
            final pieces = <Widget>[];
            final stackCount = <String, int>{};
            for (final seat in game.seats) {
              for (var p = 0; p < 4; p++) {
                final st = game.steps[seat]![p];
                Offset pos;
                if (st < 0) {
                  pos = _baseSlot(seat, p);
                } else {
                  final c = cellFor(seat, st);
                  pos = Offset(c[0].toDouble(), c[1].toDouble());
                  final key = '${c[0]},${c[1]}';
                  final n = stackCount[key] = (stackCount[key] ?? 0) + 1;
                  pos += Offset((n - 1) * .18, (n - 1) * .18);
                }
                final glow = seat == cur && movable.contains(p) && !busy && !_computerTurn;
                pieces.add(Positioned(
                  left: pos.dx * cell,
                  top: pos.dy * cell,
                  width: cell,
                  height: cell,
                  child: GestureDetector(
                    onTap: () => _tapPiece(seat, p),
                    child: Container(
                      margin: EdgeInsets.all(cell * .12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _seatColors[seat],
                        border: Border.all(color: glow ? Colors.white : Colors.black54, width: glow ? 3 : 1.5),
                        boxShadow: glow
                            ? [BoxShadow(color: _seatColors[seat], blurRadius: 8, spreadRadius: 2)]
                            : const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ));
              }
            }
            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _LudoBoard())),
              ...pieces,
            ]);
          }),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (lastRoll != null) DieFace(lastRoll!, size: 48),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: !busy && !_computerTurn && game.dice == null && !game.over ? _roll : null,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Roll'),
          ),
        ]),
      ],
    );
  }
}

class _LudoBoard extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final paint = Paint();
    Rect r(num c, num row, [num w = 1, num h = 1]) =>
        Rect.fromLTWH(c * cell, row * cell, w * cell, h * cell);
    canvas.drawRect(r(0, 0, 15, 15), paint..color = Colors.white);
    // Bases (rotated from green's top-left quadrant).
    for (var seat = 0; seat < 4; seat++) {
      final o = [const Offset(0, 0), const Offset(9, 0), const Offset(9, 9), const Offset(0, 9)][seat];
      canvas.drawRect(r(o.dx, o.dy, 6, 6), paint..color = _seatColors[seat]);
      canvas.drawRect(r(o.dx + 1, o.dy + 1, 4, 4), paint..color = Colors.white);
      // Home column and start square.
      for (var st = 51; st < 56; st++) {
        final c = cellFor(seat, st);
        canvas.drawRect(r(c[0], c[1]), paint..color = _seatColors[seat].withValues(alpha: .8));
      }
      final s = cellFor(seat, 0);
      canvas.drawRect(r(s[0], s[1]), paint..color = _seatColors[seat].withValues(alpha: .8));
    }
    // Centre triangles.
    final centre = Offset(7.5 * cell, 7.5 * cell);
    final corners = [
      [Offset(6 * cell, 6 * cell), Offset(6 * cell, 9 * cell)], // green (left)
      [Offset(6 * cell, 6 * cell), Offset(9 * cell, 6 * cell)], // yellow (top)
      [Offset(9 * cell, 6 * cell), Offset(9 * cell, 9 * cell)], // blue (right)
      [Offset(6 * cell, 9 * cell), Offset(9 * cell, 9 * cell)], // red (bottom)
    ];
    for (var seat = 0; seat < 4; seat++) {
      final path = Path()
        ..moveTo(corners[seat][0].dx, corners[seat][0].dy)
        ..lineTo(corners[seat][1].dx, corners[seat][1].dy)
        ..lineTo(centre.dx, centre.dy)
        ..close();
      canvas.drawPath(path, paint..color = _seatColors[seat]);
    }
    // Grid lines on the cross.
    final line = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 15; i++) {
      for (var j = 0; j < 15; j++) {
        final inCross = (i >= 6 && i <= 8) != (j >= 6 && j <= 8);
        if (inCross) canvas.drawRect(r(i, j), line);
      }
    }
    // Safe-square stars.
    for (final s in safeSquares) {
      final tp = TextPainter(
        text: TextSpan(text: '★', style: TextStyle(fontSize: cell * .6, color: Colors.black38)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((s[0] + .5) * cell - tp.width / 2, (s[1] + .5) * cell - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_LudoBoard old) => false;
}
