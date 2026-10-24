import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'dots_engine.dart';

class DotsAndBoxesScreen extends StatefulWidget {
  const DotsAndBoxesScreen({super.key});
  @override
  State<DotsAndBoxesScreen> createState() => _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  int size = 4;
  late DotsGame game = DotsGame(rows: size, cols: size);
  bool busy = false;
  int generation = 0;

  static const _p1 = Color(0xFF1E88E5), _p2 = Color(0xFFE53935);

  void _newGame() => setState(() {
        generation++;
        busy = false;
        game = DotsGame(rows: size, cols: size);
      });

  Future<void> _computer() async {
    if (!vsComputer || busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && !game.over && game.turn == 2) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || token != generation) return;
      setState(() => game.play(game.aiMove(level.index, rng)));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _tap(int e) {
    if (busy || game.over || (vsComputer && game.turn == 2)) return;
    setState(() => game.play(e));
    _computer();
  }

  @override
  Widget build(BuildContext context) {
    final s = game.scores;
    final names = vsComputer ? ['You', 'Computer'] : ['Blue', 'Red'];
    final status = game.over
        ? (s[0] == s[1] ? 'Tie ${s[0]}–${s[1]}' : '${s[0] > s[1] ? names[0] : names[1]} win${s[0] > s[1] && vsComputer ? '' : 's'} ${max(s[0], s[1])}–${min(s[0], s[1])}')
        : '${names[game.turn - 1]} to draw a line · ${names[0]} ${s[0]} – ${s[1]} ${names[1]}';
    return GameScaffold(
      gameId: 'dots_and_boxes',
      completed: game.over && (!vsComputer || game.scores[0] > game.scores[1]),
      title: 'Dots and Boxes',
      onNewGame: _newGame,
      rules: 'Take turns drawing a line between two neighbouring dots. If '
          'your line completes the fourth side of a box, you claim it and '
          'must draw another line. The player with more boxes at the end '
          'wins. Avoid drawing the third side of a box — your opponent will '
          'take it, and maybe a whole chain.',
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
            ButtonSegment(value: 3, label: Text('3×3')),
            ButtonSegment(value: 4, label: Text('4×4')),
            ButtonSegment(value: 5, label: Text('5×5')),
            ButtonSegment(value: 6, label: Text('6×6')),
          ],
          selected: {size},
          onSelectionChanged: (v) {
            size = v.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: game.over),
        LandscapeBoard(child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final gap = box.maxWidth / (size + .6);
            final pad = gap * .3;
            final colors = Theme.of(context).colorScheme;
            final widgets = <Widget>[];
            for (var b = 0; b < game.boxes.length; b++) {
              if (game.boxes[b] == 0) continue;
              widgets.add(Positioned(
                left: pad + (b % size) * gap,
                top: pad + (b ~/ size) * gap,
                width: gap,
                height: gap,
                child: Container(
                  color: (game.boxes[b] == 1 ? _p1 : _p2).withValues(alpha: .3),
                  alignment: Alignment.center,
                  child: Text(game.boxes[b] == 1 ? names[0][0] : names[1][0],
                      style: TextStyle(fontSize: gap * .35, fontWeight: FontWeight.bold)),
                ),
              ));
            }
            for (var e = 0; e < game.edgeCount; e++) {
              final horizontal = e < game.h.length;
              final k = horizontal ? e : e - game.h.length;
              final r = horizontal ? k ~/ size : k ~/ (size + 1);
              final c = horizontal ? k % size : k % (size + 1);
              final owner = horizontal ? game.h[k] : game.v[k];
              final thick = gap * .12;
              widgets.add(Positioned(
                left: pad + c * gap + (horizontal ? thick : -gap * .2),
                top: pad + r * gap + (horizontal ? -gap * .2 : thick),
                width: horizontal ? gap - 2 * thick : gap * .4,
                height: horizontal ? gap * .4 : gap - 2 * thick,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tap(e),
                  child: Center(
                    child: Container(
                      width: horizontal ? double.infinity : thick,
                      height: horizontal ? thick : double.infinity,
                      decoration: BoxDecoration(
                        color: owner == 0 ? colors.outlineVariant.withValues(alpha: .35) : owner == 1 ? _p1 : _p2,
                        borderRadius: BorderRadius.circular(thick),
                      ),
                    ),
                  ),
                ),
              ));
            }
            for (var r = 0; r <= size; r++) {
              for (var c = 0; c <= size; c++) {
                widgets.add(Positioned(
                  left: pad + c * gap - gap * .08,
                  top: pad + r * gap - gap * .08,
                  width: gap * .16,
                  height: gap * .16,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colors.onSurface, shape: BoxShape.circle),
                    ),
                  ),
                ));
              }
            }
            return Stack(clipBehavior: Clip.none, children: widgets);
          }),
        )),
      ],
    );
  }
}
