import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'chinese_checkers_engine.dart';

const _colors = [
  Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5),
  Color(0xFFFDD835), Color(0xFF8E24AA), Color(0xFFFF8F00),
];

class ChineseCheckersScreen extends StatefulWidget {
  const ChineseCheckersScreen({super.key});
  @override
  State<ChineseCheckersScreen> createState() => _ChineseCheckersScreenState();
}

class _ChineseCheckersScreenState extends State<ChineseCheckersScreen> {
  int players = 2;
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late ChineseCheckers game = ChineseCheckers(players: players);
  Hole? selected;
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        selected = null;
        game = ChineseCheckers(players: players);
      });

  Color _colorFor(int p) => _colors[game.corners[p].index];

  Future<void> _bots() async {
    if (busy || !vsComputer) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && game.winner == null && game.turn != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || token != generation) return;
      final (f, t) = game.aiMove(level.index);
      setState(() => game.move(f, t));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _tap(Hole h) {
    if (busy || game.winner != null || (vsComputer && game.turn != 0)) return;
    setState(() {
      if (selected != null && game.destinations(selected!).contains(h)) {
        game.move(selected!, h);
        selected = null;
      } else if (game.owner[h] == game.turn) {
        selected = h;
      } else {
        selected = null;
      }
    });
    _bots();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final targets = selected == null ? <Hole>{} : game.destinations(selected!).toSet();
    String name(int p) => vsComputer ? (p == 0 ? 'You' : 'Computer ${p + 1}') : 'Player ${p + 1}';
    final status = game.winner != null
        ? '${name(game.winner!)} ${game.winner == 0 && vsComputer ? 'win' : 'wins'} in ${game.moves} moves!'
        : busy
            ? '${name(game.turn)} is moving…'
            : '${name(game.turn)} to move';
    return GameScaffold(
      gameId: 'chinese_checkers',
      completed: game.winner == 0 || (!vsComputer && game.winner != null),
      title: 'Chinese Checkers',
      onNewGame: _newGame,
      rules: 'Move all ten of your marbles into the point of the star '
          'opposite your own. On your turn move one marble to a neighbouring '
          'empty hole, or hop over an adjacent marble (any colour) into the '
          'empty hole directly beyond — hops can be chained. You start at '
          'the bottom.',
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
            ButtonSegment(value: 2, label: Text('2 players')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 6, label: Text('6')),
          ],
          selected: {players},
          onSelectionChanged: (s) {
            players = s.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: game.winner != null),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var p = 0; p < game.corners.length; p++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CircleAvatar(
                radius: game.turn == p ? 12 : 8,
                backgroundColor: _colorFor(p),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        LandscapeBoard(child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            // x = q + r/2 spans -8..8, y = r·√3/2 spans ±6.93.
            final unit = box.maxWidth / 17.5;
            final cx = box.maxWidth / 2, cy = box.maxWidth / 2;
            final d = unit * .82;
            return Stack(children: [
              for (final h in game.holes)
                Positioned(
                  left: cx + (h.q + h.r / 2) * unit - d / 2,
                  top: cy + h.r * sqrt(3) / 2 * unit - d / 2,
                  width: d,
                  height: d,
                  child: GestureDetector(
                    onTap: () => _tap(h),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: game.owner.containsKey(h)
                            ? _colorFor(game.owner[h]!)
                            : targets.contains(h)
                                ? colors.primary.withValues(alpha: .5)
                                : colors.surfaceContainerHighest,
                        border: Border.all(
                          color: selected == h ? colors.onSurface : Colors.black26,
                          width: selected == h ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        )),
      ],
    );
  }
}
