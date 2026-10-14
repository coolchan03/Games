import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'morris_engine.dart';

class NineMensMorrisScreen extends StatefulWidget {
  const NineMensMorrisScreen({super.key});
  @override
  State<NineMensMorrisScreen> createState() => _NineMensMorrisScreenState();
}

class _NineMensMorrisScreenState extends State<NineMensMorrisScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  MorrisState game = MorrisState();
  int? from;
  (int?, int)? pendingRemoval;
  bool thinking = false;
  int generation = 0;

  static const _w = Color(0xFFF5F0E6), _b = Color(0xFF263238);

  void _newGame() => setState(() {
        generation++;
        game = MorrisState();
        from = null;
        pendingRemoval = null;
        thinking = false;
      });

  Future<void> _computer() async {
    if (!vsComputer || game.turn != 2 || game.result != 0) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || token != generation) return;
    final m = morrisAi(game, level.index, rng);
    setState(() {
      game.apply(m);
      thinking = false;
    });
  }

  void _tap(int i) {
    if (thinking || game.result != 0) return;
    if (vsComputer && game.turn == 2) return;
    setState(() {
      if (pendingRemoval != null) {
        if (game.removable(game.turn).contains(i)) {
          game.apply(MorrisMove(pendingRemoval!.$2, from: pendingRemoval!.$1, remove: i));
          pendingRemoval = null;
        }
        return;
      }
      final steps = game.steps();
      if (game.placing(game.turn)) {
        if (!steps.contains((null, i))) return;
        _commit(null, i);
        return;
      }
      if (game.board[i] == game.turn) {
        from = from == i ? null : i;
        return;
      }
      if (from != null && steps.contains((from, i))) {
        _commit(from, i);
        from = null;
      }
    });
    _computer();
  }

  void _commit(int? f, int to) {
    if (game.formsMill(f, to)) {
      // Show the piece in place while the player chooses what to remove.
      pendingRemoval = (f, to);
    } else {
      game.apply(MorrisMove(to, from: f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = game.result;
    String name(int p) => p == 1 ? (vsComputer ? 'You (white)' : 'White') : (vsComputer ? 'Computer' : 'Black');
    String status;
    if (r == 3) {
      status = 'Draw';
    } else if (r != 0) {
      status = '${name(r)} ${vsComputer && r == 1 ? 'win' : 'wins'}!';
    } else if (pendingRemoval != null) {
      status = 'Mill! Tap an opponent piece to remove';
    } else if (thinking) {
      status = 'Computer is thinking…';
    } else {
      final p = game.turn;
      status = '${name(p)}: ${game.placing(p) ? 'place a piece (${game.inHand[p - 1]} left)' : game.flying(p) ? 'fly a piece anywhere' : 'slide a piece'}';
    }
    // Board with a pending placement drawn in.
    final shown = List.of(game.board);
    if (pendingRemoval != null) {
      if (pendingRemoval!.$1 != null) shown[pendingRemoval!.$1!] = 0;
      shown[pendingRemoval!.$2] = game.turn;
    }
    final removable = pendingRemoval == null ? <int>{} : game.removable(game.turn).toSet();
    final targets = from == null ? <int>{} : {for (final s in game.steps()) if (s.$1 == from) s.$2};
    return GameScaffold(
      title: "Nine Men's Morris",
      onNewGame: _newGame,
      rules: 'Each player has nine pieces. First take turns placing them on '
          'empty points. Three in a row along a line is a "mill" and lets you '
          'remove one opposing piece (not one in a mill, unless no other is '
          'available). When all pieces are placed, slide one piece to an '
          'adjacent empty point per turn. A player reduced to three pieces may '
          '"fly" to any empty point. You lose with fewer than three pieces or '
          'no legal move.',
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
        StatusBanner(status, highlight: r != 0 || pendingRemoval != null),
        Text('White ${game.total(1)} · Black ${game.total(2)} pieces', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final step = box.maxWidth / 7;
            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _MorrisBoard(colors.onSurface))),
              for (var i = 0; i < 24; i++)
                Positioned(
                  left: morrisCoords[i].$1 * step,
                  top: morrisCoords[i].$2 * step,
                  width: step,
                  height: step,
                  child: GestureDetector(
                    onTap: () => _tap(i),
                    child: Center(
                      child: Container(
                        width: step * (shown[i] == 0 ? .3 : .7),
                        height: step * (shown[i] == 0 ? .3 : .7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: shown[i] == 0
                              ? (targets.contains(i) ? colors.primary : colors.onSurface)
                              : shown[i] == 1
                                  ? _w
                                  : _b,
                          border: Border.all(
                            color: removable.contains(i)
                                ? Colors.red
                                : from == i
                                    ? colors.primary
                                    : Colors.black54,
                            width: removable.contains(i) || from == i ? 4 : 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ],
    );
  }
}

class _MorrisBoard extends CustomPainter {
  _MorrisBoard(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 7;
    final p = Paint()
      ..color = color.withValues(alpha: .6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    Offset at(int i) => Offset((morrisCoords[i].$1 + .5) * s, (morrisCoords[i].$2 + .5) * s);
    for (var i = 0; i < 24; i++) {
      for (final j in morrisAdjacent[i]) {
        if (j > i) canvas.drawLine(at(i), at(j), p);
      }
    }
  }

  @override
  bool shouldRepaint(_MorrisBoard old) => old.color != color;
}
