import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';

/// Sixteen (after Simon Tatham's Portable Puzzle Collection, sixteen.c,
/// MIT): restore the grid by cyclically shifting whole rows and columns.
class SixteenGame {
  SixteenGame({this.n = 4, int scramble = 0, Random? random}) {
    tiles = List.generate(n * n, (i) => i + 1);
    final rng = random ?? Random();
    final shifts = scramble > 0 ? scramble : n * n * 3;
    do {
      for (var k = 0; k < shifts; k++) {
        if (rng.nextBool()) {
          shiftRow(rng.nextInt(n), rng.nextBool() ? 1 : -1, count: false);
        } else {
          shiftCol(rng.nextInt(n), rng.nextBool() ? 1 : -1, count: false);
        }
      }
    } while (solved);
  }

  final int n;
  late List<int> tiles;
  int moves = 0;

  bool get solved {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  void shiftRow(int r, int by, {bool count = true}) {
    final row = [for (var c = 0; c < n; c++) tiles[r * n + c]];
    for (var c = 0; c < n; c++) {
      tiles[r * n + (c + by) % n] = row[c];
    }
    if (count) moves++;
  }

  void shiftCol(int c, int by, {bool count = true}) {
    final col = [for (var r = 0; r < n; r++) tiles[r * n + c]];
    for (var r = 0; r < n; r++) {
      tiles[((r + by) % n) * n + c] = col[r];
    }
    if (count) moves++;
  }
}

/// The 20 numbered Sixteen levels: grid size and number of random shifts
/// used to scramble it grow together. Every level is scrambled from the
/// solved grid by legal shifts, so it can always be solved.
class SixteenLevels {
  static const _specs = [
    (3, 2),
    (3, 3),
    (3, 4),
    (3, 6),
    (3, 9),
    (3, 27),
    (4, 3),
    (4, 4),
    (4, 6),
    (4, 8),
    (4, 12),
    (4, 18),
    (4, 48),
    (5, 4),
    (5, 6),
    (5, 9),
    (5, 14),
    (5, 20),
    (5, 35),
    (5, 75),
  ];

  static int sizeFor(int level) => _specs[level - 1].$1;
  static int shiftsFor(int level) => _specs[level - 1].$2;

  static SixteenGame build(int level) => SixteenGame(
        n: sizeFor(level),
        scramble: shiftsFor(level),
        random: Random(1600 + level * 53),
      );
}

class SixteenScreen extends StatefulWidget {
  const SixteenScreen({super.key});
  @override
  State<SixteenScreen> createState() => _SixteenScreenState();
}

class _SixteenScreenState extends State<SixteenScreen> {
  int level = CampaignLevelBar.initialLevel('sixteen');
  late SixteenGame game = _build(level);

  /// Builds [level], resuming a saved unfinished attempt when [resume].
  SixteenGame _build(int level, {bool resume = true}) {
    final g = SixteenLevels.build(level);
    final saved =
        resume ? CampaignLevelBar.restoreActive('sixteen', level) : null;
    if (saved != null &&
        saved.length == g.tiles.length + 1 &&
        listEquals(([...saved.sublist(1)]..sort()), ([...g.tiles]..sort()))) {
      g.moves = saved[0];
      g.tiles = saved.sublist(1);
    }
    return g;
  }

  int get n => game.n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget arrow(IconData icon, VoidCallback onTap) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: game.solved ? null : () => setState(onTap),
          icon: Icon(icon, size: 20),
        );
    return GameScaffold(
      gameId: 'sixteen',
      completed: game.solved,
      title: 'Sixteen',
      onNewGame: () => setState(() => game = _build(level, resume: false)),
      rules: 'Put the numbers back in order. Use the arrows around the edge '
          'to slide a whole row or column one step; the tile pushed off one '
          'end comes back on the other. From Simon Tatham\'s Portable Puzzle '
          'Collection.\n\nThere are 20 levels, from lightly shuffled 3×3 grids '
          'to thoroughly shuffled 5×5 ones. New game restarts the current '
          'level.',
      children: [
        CampaignLevelBar(
          gameId: 'sixteen',
          level: level,
          solved: game.solved,
          onLevel: (value) => setState(() {
            level = value;
            game = _build(level);
          }),
          describe: (l) {
            final s = SixteenLevels.sizeFor(l);
            return '$s×$s';
          },
          activeState: [game.moves, ...game.tiles],
          result: CampaignResult(
            score: game.moves,
            stars: starsForPar(game.moves, SixteenLevels.shiftsFor(level)),
            label: (m) => '$m moves',
          ),
        ),
        StatusBanner(
            game.solved
                ? 'Solved in ${game.moves} moves!'
                : 'Moves: ${game.moves}',
            highlight: game.solved),
        LandscapeBoard(child: LayoutBuilder(builder: (context, box) {
          final cell = (box.maxWidth - 80) / n;
          return Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 40),
              for (var c = 0; c < n; c++)
                SizedBox(
                    width: cell,
                    child:
                        arrow(Icons.arrow_upward, () => game.shiftCol(c, -1))),
              const SizedBox(width: 40),
            ]),
            for (var r = 0; r < n; r++)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    width: 40,
                    child: arrow(Icons.arrow_back, () => game.shiftRow(r, -1))),
                for (var c = 0; c < n; c++)
                  Container(
                    width: cell - 6,
                    height: cell - 6,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: game.tiles[r * n + c] == r * n + c + 1
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('${game.tiles[r * n + c]}',
                        style: TextStyle(
                            fontSize: cell * .35, fontWeight: FontWeight.bold)),
                  ),
                SizedBox(
                    width: 40,
                    child:
                        arrow(Icons.arrow_forward, () => game.shiftRow(r, 1))),
              ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 40),
              for (var c = 0; c < n; c++)
                SizedBox(
                    width: cell,
                    child:
                        arrow(Icons.arrow_downward, () => game.shiftCol(c, 1))),
              const SizedBox(width: 40),
            ]),
          ]);
        })),
      ],
    );
  }
}
