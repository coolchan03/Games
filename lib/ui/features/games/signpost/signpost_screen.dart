import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'signpost_engine.dart';

class SignpostScreen extends StatefulWidget {
  const SignpostScreen({super.key});
  @override
  State<SignpostScreen> createState() => _SignpostScreenState();
}

class _SignpostScreenState extends State<SignpostScreen> {
  int level = CampaignLevelBar.initialLevel('signpost');
  late SignpostGame game = SignpostGame(SignpostLevels.build(level));
  int? from;

  int get size => game.puzzle.w;

  static const _icons = [
    Icons.north, Icons.north_east, Icons.east, Icons.south_east,
    Icons.south, Icons.south_west, Icons.west, Icons.north_west,
  ];

  void _newGame() => setState(() {
        game = SignpostGame(SignpostLevels.build(level));
        from = null;
      });

  void _setLevel(int value) {
    level = value;
    _newGame();
  }

  void _tap(int cell) {
    setState(() {
      if (from == null) {
        if (game.puzzle.arrows[cell] >= 0) from = cell;
      } else if (from == cell) {
        game.unlink(cell);
        from = null;
      } else if (game.canLink(from!, cell)) {
        game.link(from!, cell);
        from = null;
      } else {
        from = game.puzzle.arrows[cell] >= 0 ? cell : null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final p = game.puzzle;
    final nums = game.numbers();
    final solved = game.solved;
    final targets = from == null ? <int>{} : p.ray(from!, p.arrows[from!]).toSet();
    // Colour unnumbered chains so they are easy to follow.
    final chainColour = <int, Color>{};
    final palette = [Colors.teal, Colors.orange, Colors.purple, Colors.brown, Colors.pink, Colors.indigo];
    var k = 0;
    for (var i = 0; i < p.n; i++) {
      if (nums[i] != null || chainColour.containsKey(i)) continue;
      if (game.next[i] == null && game.prev(i) == null) continue;
      var head = i;
      while (game.prev(head) != null && !chainColour.containsKey(game.prev(head))) {
        head = game.prev(head)!;
      }
      final col = palette[k++ % palette.length];
      for (int? c = head; c != null && !chainColour.containsKey(c); c = game.next[c]) {
        chainColour[c] = col;
      }
    }
    return GameScaffold(
      gameId: 'signpost',
      completed: solved,
      title: 'Signpost',
      onNewGame: _newGame,
      rules: 'Link every square into one chain numbered 1 to ${p.n}. Each '
          'square\'s arrow points toward the next square in the chain — it '
          'can be any distance away in that direction. Some numbers are '
          'given. Tap a square, then tap the square it should lead to; tap a '
          'square twice to clear its link. Every puzzle has exactly one '
          'solution. There are 20 levels, growing from 4×4 to 6×6; New game '
          'restarts the current level. From Simon Tatham\'s Portable Puzzle Collection.',
      children: [
        CampaignLevelBar(
          gameId: 'signpost',
          level: level,
          solved: solved,
          onLevel: _setLevel,
          describe: (n) {
            final s = SignpostLevels.sizeFor(n);
            return '$s×$s';
          },
        ),
        StatusBanner(solved ? 'Solved!' : from == null ? 'Tap a square to start a link' : 'Now tap a highlighted square', highlight: solved),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final cell = box.maxWidth / size;
            return Stack(children: [
              CustomPaint(
                size: Size(box.maxWidth, box.maxWidth),
                painter: _Links(game, cell, colors.primary.withValues(alpha: .5)),
              ),
              for (var i = 0; i < p.n; i++)
                Positioned(
                  left: (i % size) * cell,
                  top: (i ~/ size) * cell,
                  width: cell,
                  height: cell,
                  child: GestureDetector(
                    onTap: () => _tap(i),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: from == i
                            ? colors.primaryContainer
                            : targets.contains(i)
                                ? colors.tertiaryContainer
                                : (chainColour[i] ?? colors.surfaceContainerHighest)
                                    .withValues(alpha: chainColour[i] == null ? 1 : .35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: p.clues.containsKey(i) ? colors.onSurface : colors.outlineVariant,
                          width: p.clues.containsKey(i) ? 2 : 1,
                        ),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: p.arrows[i] < 0
                                ? Icon(Icons.star, size: cell * .3)
                                : Icon(_icons[p.arrows[i]], size: cell * .3),
                          ),
                        ),
                        if (nums[i] != null)
                          Text('${nums[i]! + 1}',
                              style: TextStyle(
                                fontSize: cell * .32,
                                fontWeight: p.clues.containsKey(i) ? FontWeight.w900 : FontWeight.w500,
                              )),
                      ]),
                    ),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() {
            for (var i = 0; i < p.n; i++) {
              game.next[i] = null;
            }
            from = null;
          }),
          child: const Text('Clear all links'),
        ),
      ],
    );
  }
}

class _Links extends CustomPainter {
  _Links(this.game, this.cell, this.color);
  final SignpostGame game;
  final double cell;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = game.puzzle.w;
    final paint = Paint()
      ..color = color
      ..strokeWidth = max(3, cell * .06)
      ..strokeCap = StrokeCap.round;
    Offset c(int i) => Offset((i % w + .5) * cell, (i ~/ w + .5) * cell);
    for (var i = 0; i < game.next.length; i++) {
      final n = game.next[i];
      if (n != null) canvas.drawLine(c(i), c(n), paint);
    }
  }

  @override
  bool shouldRepaint(_Links old) => true;
}
