import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'same_game_engine.dart';

const _palette = [
  Colors.transparent,
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
];

class SameGameScreen extends StatefulWidget {
  const SameGameScreen({super.key});
  @override
  State<SameGameScreen> createState() => _SameGameScreenState();
}

class _SameGameScreenState extends State<SameGameScreen> {
  int level = CampaignLevelBar.initialLevel('same_game');
  late SameGame game = SameGameLevels.build(level);
  Set<int> preview = {};

  void _newGame() => setState(() {
        game = SameGameLevels.build(level);
        preview = {};
      });

  void _tap(int i) {
    setState(() {
      final g = game.group(i).toSet();
      if (preview.contains(i)) {
        game.remove(i);
        preview = {};
      } else {
        preview = g.length >= 2 ? g : {};
      }
    });
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
          'clearing the whole board earns a 1000-point bonus.\n\nThere are 20 '
          'levels, from a two-colour 5×5 board to a five-colour 12×12 one. '
          'Every level can be cleared completely, and clearing it completes '
          'the level; New game restarts it.\n\nRules from '
          'Simon Tatham\'s Portable Puzzle Collection.',
      children: [
        CampaignLevelBar(
          gameId: 'same_game',
          level: level,
          solved: game.cleared,
          onLevel: (value) {
            level = value;
            _newGame();
          },
          describe: (l) {
            final (w, h, c) = SameGameLevels.specs[l - 1];
            return '$w×$h, $c colours';
          },
        ),
        Row(children: [
          Expanded(
              child:
                  StatusBanner(status, highlight: game.cleared || game.stuck)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo
                ? () => setState(() {
                      game.undo();
                      preview = {};
                    })
                : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AspectRatio(
            aspectRatio: game.w / game.h,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: game.w),
              itemCount: game.w * game.h,
              itemBuilder: (context, i) {
                final c = game.grid[i];
                return GestureDetector(
                  onTap: c == 0 ? null : () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.all(preview.contains(i) ? 3.5 : 1.5),
                    decoration: c == 0
                        ? null
                        : BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-.4, -.45),
                              radius: 1.1,
                              colors: [
                                Color.lerp(_palette[c], Colors.white, .55)!,
                                _palette[c],
                                Color.lerp(_palette[c], Colors.black, .35)!,
                              ],
                              stops: const [0, .45, 1],
                            ),
                            borderRadius: BorderRadius.circular(
                                preview.contains(i) ? 14 : 7),
                            border: Border.all(
                              color: preview.contains(i)
                                  ? Colors.white
                                  : Color.lerp(_palette[c], Colors.black, .4)!,
                              width: preview.contains(i) ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: preview.contains(i)
                                    ? _palette[c].withValues(alpha: .8)
                                    : Colors.black26,
                                blurRadius: preview.contains(i) ? 8 : 2,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
