import 'dart:async';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import 'same_game_engine.dart';

const _palette = [
  Colors.transparent, Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047),
  Color(0xFFFDD835), Color(0xFF8E24AA),
];

class SameGameScreen extends StatefulWidget {
  const SameGameScreen({super.key});
  @override
  State<SameGameScreen> createState() => _SameGameScreenState();
}

class _SameGameScreenState extends State<SameGameScreen> {
  int colours = 3;
  bool solvable = true;
  late SameGame game = _load();
  Set<int> preview = {};

  int get _mode => (colours - 3) * 2 + (solvable ? 1 : 2);

  SameGame _load() {
    final saved = CampaignProgress.loadActive('same_game', _mode,
        maxLength: 103);
    final result = SameGame(colours: colours, solvable: solvable);
    if (saved != null) result.restore(saved);
    return result;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
      'same_game', _mode, game.snapshot()));

  void _newGame() {
    setState(() {
      game = SameGame(colours: colours, solvable: solvable);
      preview = {};
    });
    _save();
  }

  void _undo() {
    if (!game.canUndo) return;
    setState(() { game.undo(); preview = {}; });
    _save();
  }

  void _tap(int i) {
    var changed = false;
    setState(() {
      final g = game.group(i).toSet();
      if (preview.contains(i)) {
        changed = game.remove(i);
        preview = {};
      } else {
        preview = g.length >= 2 ? g : {};
      }
    });
    if (changed) _save();
  }

  @override
  Widget build(BuildContext context) {
    final status = game.cleared
        ? 'Board cleared! Score ${game.score} (includes 1000 bonus)'
        : game.stuck
            ? 'No more groups · ${game.remaining} left · score ${game.score}'
            : preview.isNotEmpty
                ? 'Tap again to remove ${preview.length} for ${SameGame.points(preview.length)} points'
                : 'Score ${game.score} · ${game.remaining} tiles left';
    return GameScaffold(
      gameId: 'same_game',
      completed: game.cleared,
      title: 'Same Game',
      onNewGame: _newGame,
      rules: 'Tap a group of two or more touching tiles of the same colour '
          'to select it, and tap again to remove it. Tiles above fall down '
          'and empty columns close up. Removing n tiles scores (n − 2)²; '
          'clearing the whole board earns a 1000-point bonus. With '
          '"Solvable" on, every board can be cleared completely.\n\nRules from '
          'Simon Tatham\'s Portable Puzzle Collection.',
      children: [
        Row(children: [
          Expanded(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 3, label: Text('3 colours')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5')),
              ],
              selected: {colours},
              onSelectionChanged: (s) {
                setState(() {
                  colours = s.first;
                  game = _load();
                  preview = {};
                });
              },
            ),
          ),
        ]),
        SwitchListTile(
          title: const Text('Solvable boards'),
          value: solvable,
          onChanged: (v) {
            setState(() {
              solvable = v;
              game = _load();
              preview = {};
            });
          },
        ),
        Row(children: [
          Expanded(child: StatusBanner(status, highlight: game.cleared || game.stuck)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        AspectRatio(
          aspectRatio: game.w / game.h,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: game.w),
            itemCount: game.w * game.h,
            itemBuilder: (context, i) {
              final c = game.grid[i];
              return GestureDetector(
                onTap: c == 0 ? null : () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.all(preview.contains(i) ? 4 : 1.5),
                  decoration: BoxDecoration(
                    color: _palette[c],
                    borderRadius: BorderRadius.circular(preview.contains(i) ? 12 : 5),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
