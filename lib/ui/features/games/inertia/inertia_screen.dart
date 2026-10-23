import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'inertia_engine.dart';

class InertiaScreen extends StatefulWidget {
  const InertiaScreen({super.key});
  @override
  State<InertiaScreen> createState() => _InertiaScreenState();
}

class _InertiaScreenState extends State<InertiaScreen> {
  int level = CampaignLevelBar.initialLevel('inertia');
  late InertiaGame game = InertiaLevels.build(level);
  final focus = FocusNode();

  static const _arrows = [
    Icons.north, Icons.north_east, Icons.east, Icons.south_east,
    Icons.south, Icons.south_west, Icons.west, Icons.north_west,
  ];

  void _move(int d) => setState(() => game.move(d));

  /// Tapping a square moves toward it if it lies on one of the 8 lines.
  void _tapCell(int x, int y) {
    final dx = x - game.px, dy = y - game.py;
    if (dx == 0 && dy == 0) return;
    if (dx != 0 && dy != 0 && dx.abs() != dy.abs()) return;
    for (var d = 0; d < 8; d++) {
      if (dirX(d) == dx.sign && dirY(d) == dy.sign) {
        _move(d);
        return;
      }
    }
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final map = {
      LogicalKeyboardKey.arrowUp: 0, LogicalKeyboardKey.numpad9: 1, LogicalKeyboardKey.arrowRight: 2,
      LogicalKeyboardKey.numpad3: 3, LogicalKeyboardKey.arrowDown: 4, LogicalKeyboardKey.numpad1: 5,
      LogicalKeyboardKey.arrowLeft: 6, LogicalKeyboardKey.numpad7: 7,
    };
    final d = map[e.logicalKey];
    if (d == null) return KeyEventResult.ignored;
    _move(d);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = game.dead
        ? 'Boom! You hit a mine — undo or start again'
        : game.won
            ? 'All ${game.totalGems} gems collected in ${game.moves} moves!'
            : '${game.gems} of ${game.totalGems} gems left · ${game.moves} moves';
    return GameScaffold(
      gameId: 'inertia',
      completed: game.won,
      title: 'Inertia',
      onNewGame: () => setState(() => game = InertiaLevels.build(level)),
      rules: 'Collect every gem. You slide in any of eight directions and '
          'keep going until you stop on a stop square (circle) or run into '
          'a wall — you cannot stop on open ground. Passing over a gem '
          'collects it; touching a mine ends the game (you can undo).\n\n'
          'Tap a square in line with you, use the arrow buttons, or the '
          'arrow keys / numpad. Ported from Simon Tatham\'s Portable Puzzle '
          'Collection; every level is generated so all gems are reachable.\n\n'
          'There are 20 levels, growing from 6×6 to 12×12. New game restarts '
          'the current level.',
      children: [
        CampaignLevelBar(
          gameId: 'inertia',
          level: level,
          solved: game.won,
          onLevel: (value) => setState(() {
            level = value;
            game = InertiaLevels.build(level);
          }),
          describe: (l) {
            final s = InertiaLevels.sizes[l - 1];
            return '$s×$s';
          },
        ),
        StatusBanner(status, highlight: game.won || game.dead),
        Focus(
          focusNode: focus,
          autofocus: true,
          onKeyEvent: _key,
          child: AspectRatio(
            aspectRatio: game.w / game.h,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: game.w),
              itemCount: game.w * game.h,
              itemBuilder: (context, i) {
                final x = i % game.w, y = i ~/ game.w;
                final c = game.grid[i];
                final player = x == game.px && y == game.py;
                Widget? child;
                if (player) {
                  child = Icon(game.dead ? Icons.dangerous : Icons.circle,
                      color: game.dead ? Colors.red : colors.primary);
                } else if (c == Cell.gem) {
                  child = const Icon(Icons.diamond, color: Color(0xFF00ACC1));
                } else if (c == Cell.mine) {
                  child = const Icon(Icons.brightness_7, color: Color(0xFFD32F2F));
                } else if (c == Cell.stop) {
                  child = Icon(Icons.radio_button_unchecked, color: colors.outline);
                }
                return GestureDetector(
                  onTap: () => _tapCell(x, y),
                  child: Container(
                    margin: const EdgeInsets.all(.5),
                    color: c == Cell.wall ? const Color(0xFF455A64) : colors.surfaceContainerHighest,
                    child: child == null ? null : FittedBox(child: Padding(padding: const EdgeInsets.all(3), child: child)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 180,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final d in const [7, 0, 1, 6, -1, 2, 5, 4, 3])
                  d < 0
                      ? IconButton(
                          tooltip: 'Undo',
                          onPressed: game.canUndo ? () => setState(game.undo) : null,
                          icon: const Icon(Icons.undo))
                      : IconButton.filledTonal(
                          onPressed: game.canMove(d) ? () => _move(d) : null,
                          icon: Icon(_arrows[d])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
