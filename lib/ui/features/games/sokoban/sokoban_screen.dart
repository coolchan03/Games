import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/game_kit.dart';
import '../common/campaign_progress.dart';
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
  int levelNumber = CampaignProgress.selectedLevel('sokoban', count: 20);
  // Stored as 1=Medium, 2=Easy, 3=Hard to preserve the old Medium default.
  int difficulty = switch (CampaignProgress.selectedLevel(
    'sokoban_difficulty', count: 3)) {
    2 => 0,
    3 => 2,
    _ => 1,
  };
  late SokobanGame game = _load();
  final focus = FocusNode();

  SokobanGame _load() {
    final (size, boxes) = [(6, 2), (7, 3), (8, 4)][difficulty];
    final result = SokobanGame(SokobanLevel.generate(
      levelNumber * 31 + difficulty, size: size, boxCount: boxes,
    ));
    final snapshot = CampaignProgress.loadActive('sokoban_$difficulty', levelNumber,
      maxLength: boxes + 3);
    if (snapshot != null) result.restore(snapshot);
    return result;
  }

  void _persist() => unawaited(CampaignProgress.saveActive(
    'sokoban_$difficulty', levelNumber, game.snapshot(),
  ));

  void _restart() {
    setState(() => game = SokobanGame(game.level));
    _persist();
  }

  void _undo() {
    if (!game.canUndo) return;
    setState(game.undo);
    _persist();
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void _setLevel(int level) {
    if (level < 1) return;
    setState(() {
      levelNumber = level;
      game = _load();
    });
    if (level <= 20) {
      unawaited(CampaignProgress.saveSelected('sokoban', level));
    }
  }

  Set<int> _completedForDifficulty() =>
      CampaignProgress.load('sokoban_$difficulty');

  void _recordSolved() {
    if (!game.solved) return;
    final completed = _completedForDifficulty();
    if (completed.add(levelNumber)) {
      unawaited(CampaignProgress.save('sokoban_$difficulty', completed));
    }
  }

  void _step(int d) {
    if (!game.step(d)) return;
    setState(_recordSolved);
    _persist();
  }

  void _tapCell(int i) {
    final w = game.level.w;
    final diff = i - game.player;
    // Adjacent: step (and push). Otherwise walk there.
    final d = diff == -w ? 0 : diff == 1 ? 1 : diff == w ? 2 : diff == -1 ? 3 : -1;
    var moved = false;
    setState(() {
      moved = d >= 0 ? game.step(d) : game.walkTo(i);
      if (moved) _recordSolved();
    });
    if (moved) _persist();
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
      _undo();
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
    final completedLevels = _completedForDifficulty();
    return GameScaffold(
      gameId: 'sokoban',
      completed: game.solved,
      title: 'Sokoban',
      onNewGame: _restart,
      rules: 'Push every crate onto a target square. You can push one crate '
          'at a time and never pull. Tap a square next to you (or use the '
          'arrows / keyboard) to step, or tap any open square to walk there. '
          'Swipe across the board to take one step in that direction. '
          'The first 20 numbered levels are available from the selector on '
          'Easy, Medium or Hard; use the arrows to explore more levels. '
          'Completion markers and unfinished crate positions are saved '
          'offline separately per difficulty. Levels are generated '
          'backwards from solved positions. '
          'Z or Backspace undoes a move.',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Easy')),
            ButtonSegment(value: 1, label: Text('Medium')),
            ButtonSegment(value: 2, label: Text('Hard')),
          ],
          selected: {difficulty},
          onSelectionChanged: (s) {
            setState(() {
              difficulty = s.first;
              game = _load();
            });
            final saved = difficulty == 0 ? 2 : difficulty == 2 ? 3 : 1;
            unawaited(CampaignProgress.saveSelected('sokoban_difficulty', saved));
          },
        ),
        Row(children: [
          const SizedBox(width: 8),
          const Text('First 20 levels:'),
          const SizedBox(width: 8),
          Expanded(child: DropdownButton<int>(
            key: const ValueKey('sokoban_level_selector'),
            isExpanded: true,
            value: levelNumber <= 20 ? levelNumber : null,
            hint: Text('Level $levelNumber'),
            items: [
              for (var n = 1; n <= 20; n++)
                DropdownMenuItem<int>(
                  value: n,
                  child: Text(
                    '${completedLevels.contains(n) ? '[Done] ' : ''}Level $n',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (level) {
              if (level != null) _setLevel(level);
            },
          )),
          const SizedBox(width: 8),
        ]),
        Row(children: [
          IconButton(
            onPressed: levelNumber > 1 ? () => _setLevel(levelNumber - 1) : null,
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
            onPressed: () => _setLevel(levelNumber + 1),
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
            onPressed: game.canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
        ]),
        if (game.solved)
          FilledButton(
            onPressed: () => _setLevel(levelNumber + 1),
            child: const Text('Next level'),
          ),
      ],
    );
  }
}
