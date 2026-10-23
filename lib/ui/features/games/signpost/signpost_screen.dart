import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import 'signpost_engine.dart';

class SignpostScreen extends StatefulWidget {
  const SignpostScreen({super.key});
  @override
  State<SignpostScreen> createState() => _SignpostScreenState();
}

class _SignpostScreenState extends State<SignpostScreen> {
  int size = CampaignProgress.selectedLevel('signpost', count: 3) + 3;
  late int seed;
  late SignpostGame game = _load();
  int? from;

  SignpostGame _load({bool fresh = false}) {
    final raw = fresh ? null : CampaignProgress.loadActive('signpost', size,
      maxLength: size * size + 1);
    seed = raw != null && raw.length == size * size + 1 && raw.first >= 0
        ? raw.first : Random().nextInt(0x7fffffff);
    final result = SignpostGame(SignpostPuzzle(
      w: size, h: size, random: Random(seed),
    ));
    if (raw != null && raw.length == size * size + 1) {
      result.restore(raw.skip(1).toList());
    }
    return result;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'signpost', size, [seed, ...game.snapshot()],
  ));

  void _undo() {
    if (!game.canUndo) return;
    setState(() { game.undo(); from = null; });
    _save();
  }

  static const _icons = [
    Icons.north, Icons.north_east, Icons.east, Icons.south_east,
    Icons.south, Icons.south_west, Icons.west, Icons.north_west,
  ];

  void _newGame() {
    setState(() {
      game = _load(fresh: true);
      from = null;
    });
    _save();
  }

  void _tap(int cell) {
    var changed = false;
    setState(() {
      if (from == null) {
        if (game.puzzle.arrows[cell] >= 0) from = cell;
      } else if (from == cell) {
        changed = game.next[cell] != null;
        game.unlink(cell);
        from = null;
      } else if (game.canLink(from!, cell)) {
        changed = game.next[from!] != cell;
        game.link(from!, cell);
        from = null;
      } else {
        from = game.puzzle.arrows[cell] >= 0 ? cell : null;
      }
    });
    if (changed) _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final p = game.puzzle;
    final nums = game.numbers();
    final solved = game.solved;
    final targets = from == null ? <int>{} :
        {for (var i = 0; i < p.n; i++) if (game.canLink(from!, i)) i};
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
          'solution. From Simon Tatham\'s Portable Puzzle Collection.',
      children: [
        SegmentedButton<int>(
          segments: [for (final s in const [4, 5, 6]) ButtonSegment(value: s, label: Text('$s×$s'))],
          selected: {size},
          onSelectionChanged: (s) {
            setState(() {
              size = s.first;
              game = _load();
              from = null;
            });
            unawaited(CampaignProgress.saveSelected('signpost', size - 3));
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
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: game.canUndo ? _undo : null,
              icon: const Icon(Icons.undo), label: const Text('Undo'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() { game.clearLinks(); from = null; });
                _save();
              },
              child: const Text('Clear all links'),
            ),
          ],
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
