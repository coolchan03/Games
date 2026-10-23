import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';

/// Twiddle (after Simon Tatham's Portable Puzzle Collection, twiddle.c,
/// MIT): restore the numbered grid by rotating square blocks.
class TwiddleGame {
  TwiddleGame({this.n = 3, this.block = 2, int scramble = 0, Random? random}) {
    tiles = List.generate(n * n, (i) => i + 1);
    final rng = random ?? Random();
    final moves = scramble > 0 ? scramble : n * n * 4;
    do {
      for (var k = 0; k < moves; k++) {
        rotate(rng.nextInt(n - block + 1), rng.nextInt(n - block + 1), rng.nextBool(), count: false);
      }
    } while (solved);
  }

  final int n, block;
  late List<int> tiles;
  int moves = 0;

  bool get solved {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  /// Rotates the block whose top-left cell is (x, y).
  void rotate(int x, int y, bool clockwise, {bool count = true}) {
    final old = List.of(tiles);
    for (var r = 0; r < block; r++) {
      for (var c = 0; c < block; c++) {
        // Destination (r, c) takes from source depending on direction.
        final (sr, sc) = clockwise ? (block - 1 - c, r) : (c, block - 1 - r);
        tiles[(y + r) * n + x + c] = old[(y + sr) * n + x + sc];
      }
    }
    if (count) moves++;
  }
}

/// The 20 numbered Twiddle levels: (grid size, block size, scramble
/// rotations). Each is scrambled from the solved grid by legal rotations,
/// so it can always be solved.
class TwiddleLevels {
  static const _specs = [
    (3, 2, 2), (3, 2, 3), (3, 2, 4), (3, 2, 6), (3, 2, 9), (3, 2, 36),
    (4, 2, 3), (4, 2, 5), (4, 2, 8), (4, 2, 12), (4, 2, 64),
    (4, 3, 3), (4, 3, 5), (4, 3, 8), (4, 3, 64),
    (5, 3, 3), (5, 3, 5), (5, 3, 8), (5, 3, 14), (5, 3, 100),
  ];

  static (int, int) configFor(int level) =>
      (_specs[level - 1].$1, _specs[level - 1].$2);

  static TwiddleGame build(int level) {
    final (n, block, scramble) = _specs[level - 1];
    return TwiddleGame(
        n: n, block: block, scramble: scramble, random: Random(2900 + level * 41));
  }
}

class TwiddleScreen extends StatefulWidget {
  const TwiddleScreen({super.key});
  @override
  State<TwiddleScreen> createState() => _TwiddleScreenState();
}

class _TwiddleScreenState extends State<TwiddleScreen> {
  int level = CampaignLevelBar.initialLevel('twiddle');
  late TwiddleGame game = TwiddleLevels.build(level);
  bool clockwise = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final n = game.n, b = game.block;
    final anchors = n - b + 1;
    return GameScaffold(
      gameId: 'twiddle',
      completed: game.solved,
      title: 'Twiddle',
      onNewGame: () => setState(() => game = TwiddleLevels.build(level)),
      rules: 'Put the numbers back in order, reading left to right and top '
          'to bottom. Tap one of the round handles to rotate the block of '
          'tiles around it; choose clockwise or anticlockwise below. From '
          'Simon Tatham\'s Portable Puzzle Collection.\n\nThere are 20 levels, '
          'from a 3×3 grid with 2×2 blocks to a 5×5 grid with 3×3 blocks. '
          'New game restarts the current level.',
      children: [
        CampaignLevelBar(
          gameId: 'twiddle',
          level: level,
          solved: game.solved,
          onLevel: (value) => setState(() {
            level = value;
            game = TwiddleLevels.build(level);
          }),
          describe: (l) {
            final (n, b) = TwiddleLevels.configFor(l);
            return '$n×$n, $b×$b blocks';
          },
        ),
        StatusBanner(game.solved ? 'Solved in ${game.moves} moves!' : 'Moves: ${game.moves}', highlight: game.solved),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final cell = box.maxWidth / n;
            return Stack(children: [
              for (var i = 0; i < n * n; i++)
                Positioned(
                  left: (i % n) * cell,
                  top: (i ~/ n) * cell,
                  width: cell,
                  height: cell,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: game.tiles[i] == i + 1 ? colors.primaryContainer : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('${game.tiles[i]}', style: TextStyle(fontSize: cell * .4, fontWeight: FontWeight.bold)),
                  ),
                ),
              for (var y = 0; y < anchors; y++)
                for (var x = 0; x < anchors; x++)
                  Positioned(
                    left: (x + b / 2) * cell - cell * .2,
                    top: (y + b / 2) * cell - cell * .2,
                    width: cell * .4,
                    height: cell * .4,
                    child: Material(
                      color: colors.primary.withValues(alpha: .85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: game.solved ? null : () => setState(() => game.rotate(x, y, clockwise)),
                        child: Icon(clockwise ? Icons.rotate_right : Icons.rotate_left, color: colors.onPrimary),
                      ),
                    ),
                  ),
            ]);
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, icon: Icon(Icons.rotate_right), label: Text('Clockwise')),
            ButtonSegment(value: false, icon: Icon(Icons.rotate_left), label: Text('Anticlockwise')),
          ],
          selected: {clockwise},
          onSelectionChanged: (s) => setState(() => clockwise = s.first),
        ),
      ],
    );
  }
}
