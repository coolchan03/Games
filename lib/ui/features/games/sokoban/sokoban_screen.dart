import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'sokoban_engine.dart';

/// A swipe changes exactly one step, avoiding accidental multi-crate pushes.
/// Diagonal swipes with equal horizontal and vertical travel are ignored.
int? sokobanSwipeDirection(int from, int to, int columns) {
  if (columns <= 0 || from < 0 || to < 0 || from == to) return null;
  final dx = to % columns - from % columns;
  final dy = to ~/ columns - from ~/ columns;
  if (dx.abs() > dy.abs()) return dx > 0 ? 1 : 3;
  if (dy.abs() > dx.abs()) return dy > 0 ? 2 : 0;
  return null;
}

class SokobanScreen extends StatefulWidget {
  const SokobanScreen({super.key});
  @override
  State<SokobanScreen> createState() => _SokobanScreenState();
}

class _SokobanScreenState extends State<SokobanScreen> {
  int levelNumber = 1;
  int difficulty = 1;
  late SokobanGame game = _load();
  final focus = FocusNode();

  SokobanGame _load() {
    final (size, boxes) = [(6, 2), (7, 3), (8, 4)][difficulty];
    return SokobanGame(SokobanLevel.generate(levelNumber * 31 + difficulty, size: size, boxCount: boxes));
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void _step(int d) => setState(() => game.step(d));

  void _tapCell(int i) {
    final w = game.level.w;
    final diff = i - game.player;
    // Adjacent: step (and push). Otherwise walk there.
    final d = diff == -w ? 0 : diff == 1 ? 1 : diff == w ? 2 : diff == -1 ? 3 : -1;
    setState(() {
      if (d >= 0) {
        game.step(d);
      } else {
        game.walkTo(i);
      }
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final map = {
      LogicalKeyboardKey.arrowUp: 0,
      LogicalKeyboardKey.arrowRight: 1,
      LogicalKeyboardKey.arrowDown: 2,
      LogicalKeyboardKey.arrowLeft: 3,
    };
    if (e.logicalKey == LogicalKeyboardKey.keyZ || e.logicalKey == LogicalKeyboardKey.backspace) {
      setState(game.undo);
      return KeyEventResult.handled;
    }
    final d = map[e.logicalKey];
    if (d == null) return KeyEventResult.ignored;
    _step(d);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lvl = game.level;
    return GameScaffold(
      gameId: 'sokoban',
      completed: game.solved,
      title: 'Sokoban',
      onNewGame: () => setState(() => game = _load()),
      rules: 'Push every crate onto a target square. You can push one crate '
          'at a time and never pull. Tap a square next to you (or use the '
          'arrows / keyboard) to step, or tap any open square to walk there. '
          'Swipe across the board to take one step in that direction. '
          'Every level is generated backwards from the solution, so all of '
          'them can be solved. Z or Backspace undoes a move.',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Easy')),
            ButtonSegment(value: 1, label: Text('Medium')),
            ButtonSegment(value: 2, label: Text('Hard')),
          ],
          selected: {difficulty},
          onSelectionChanged: (s) => setState(() {
            difficulty = s.first;
            game = _load();
          }),
        ),
        Row(children: [
          IconButton(
            onPressed: levelNumber > 1 ? () => setState(() {
              levelNumber--;
              game = _load();
            }) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: StatusBanner(
              game.solved
                  ? 'Level $levelNumber solved in ${game.moves} moves, ${game.pushes} pushes!'
                  : 'Level $levelNumber · moves ${game.moves} · pushes ${game.pushes}',
              highlight: game.solved,
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              levelNumber++;
              game = _load();
            }),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        Focus(
          focusNode: focus,
          autofocus: true,
          onKeyEvent: _key,
          child: AspectRatio(
            aspectRatio: lvl.w / lvl.h,
            child: GridBoardTouchArea(
              key: const ValueKey('sokoban_touch_board'),
              columns: lvl.w,
              rows: lvl.h,
              onTapCell: (i) {
                if (!lvl.walls.contains(i)) _tapCell(i);
              },
              onDragCell: (from, to) {
                final direction = sokobanSwipeDirection(from, to, lvl.w);
                if (direction != null) _step(direction);
              },
              child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: lvl.w),
              itemCount: lvl.w * lvl.h,
              itemBuilder: (context, i) {
                final wall = lvl.walls.contains(i);
                final goal = lvl.goals.contains(i);
                final box = game.boxes.contains(i);
                Widget? child;
                if (box) {
                  child = Icon(Icons.inventory_2, color: goal ? const Color(0xFF2E7D32) : const Color(0xFF8D6E63));
                } else if (i == game.player) {
                  child = Icon(Icons.person, color: colors.primary);
                } else if (goal) {
                  child = Icon(Icons.close, color: colors.tertiary);
                }
                return Semantics(
                  label: 'Row ${i ~/ lvl.w + 1}, column ${i % lvl.w + 1}: '
                      '${wall ? 'wall' : box ? 'crate' : i == game.player ? 'player' : goal ? 'target' : 'floor'}',
                  button: !wall,
                  onTap: wall ? null : () => _tapCell(i),
                  child: Container(
                    margin: const EdgeInsets.all(.5),
                    color: wall ? const Color(0xFF5D4037) : goal ? colors.tertiaryContainer : colors.surfaceContainerHighest,
                    child: child == null ? null : FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: child)),
                  ),
                );
              },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(onPressed: () => _step(3), icon: const Icon(Icons.arrow_back)),
          Column(children: [
            IconButton.filledTonal(onPressed: () => _step(0), icon: const Icon(Icons.arrow_upward)),
            IconButton.filledTonal(onPressed: () => _step(2), icon: const Icon(Icons.arrow_downward)),
          ]),
          IconButton.filledTonal(onPressed: () => _step(1), icon: const Icon(Icons.arrow_forward)),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: game.canUndo ? () => setState(game.undo) : null,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
        ]),
        if (game.solved)
          FilledButton(
            onPressed: () => setState(() {
              levelNumber++;
              game = _load();
            }),
            child: const Text('Next level'),
          ),
      ],
    );
  }
}\n