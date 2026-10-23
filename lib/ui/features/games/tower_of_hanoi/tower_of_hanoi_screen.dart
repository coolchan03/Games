import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';

class HanoiGame {
  HanoiGame(this.discs) : pegs = [List.generate(discs, (i) => discs - i), [], []] {
    optimal = movesToSolve();
  }

  /// Starts from an arbitrary legal position: [pegOf] gives the peg (0–2)
  /// of discs 1 (smallest) to n.
  HanoiGame.scrambled(List<int> pegOf)
      : discs = pegOf.length,
        pegs = [[], [], []] {
    for (var d = discs; d >= 1; d--) {
      pegs[pegOf[d - 1]].add(d);
    }
    optimal = movesToSolve();
  }

  final int discs;
  final List<List<int>> pegs;
  int moves = 0;

  /// Fewest moves needed from the starting position.
  late final int optimal;
  bool get solved => pegs[2].length == discs;

  /// Fewest moves from the current position to the whole tower on peg 3.
  int movesToSolve() {
    var total = 0, target = 2;
    for (var d = discs; d >= 1; d--) {
      final at = pegs.indexWhere((p) => p.contains(d));
      if (at == target) continue;
      // Disc d moves once; the smaller discs must first gather on the spare.
      total += 1 << (d - 1);
      target = 3 - at - target;
    }
    return total;
  }

  bool canMove(int from, int to) =>
      from != to && pegs[from].isNotEmpty && (pegs[to].isEmpty || pegs[to].last > pegs[from].last);

  bool move(int from, int to) {
    if (!canMove(from, to)) return false;
    pegs[to].add(pegs[from].removeLast());
    moves++;
    return true;
  }

  /// Next move of the optimal solution from the current position.
  (int, int)? hint() {
    if (solved) return null;
    // Find where each disc must go, from the largest down.
    var target = 2;
    for (var d = discs; d >= 1; d--) {
      final at = pegs.indexWhere((p) => p.contains(d));
      if (at == target) continue;
      // Disc d must move from `at` to `target`; first clear smaller discs to the spare.
      final spare = 3 - at - target;
      var smallerTarget = spare;
      for (var s = d - 1; s >= 1; s--) {
        final sAt = pegs.indexWhere((p) => p.contains(s));
        if (sAt != smallerTarget) {
          // Recurse: the largest misplaced smaller disc drives the next move.
          return _solveSub(s, sAt, smallerTarget);
        }
      }
      return (at, target);
    }
    return null;
  }

  (int, int) _solveSub(int d, int at, int target) {
    final spare = 3 - at - target;
    for (var s = d - 1; s >= 1; s--) {
      final sAt = pegs.indexWhere((p) => p.contains(s));
      if (sAt != spare) return _solveSub(s, sAt, spare);
    }
    return (at, target);
  }
}

/// The 20 numbered Tower of Hanoi levels. Classic towers of 3 to 8 discs
/// are mixed with fixed "scrambled" starts, where the discs begin spread
/// over all three pegs and the minimum is worked out for that position.
class HanoiLevels {
  /// (discs, scrambled) for each level.
  static const specs = [
    (3, false), (4, false), (4, true), (4, true), (4, true),
    (5, false), (5, true), (5, true), (5, true), (6, false),
    (6, true), (6, true), (6, true), (7, false), (7, true),
    (7, true), (7, true), (8, false), (8, true), (8, true),
  ];

  static HanoiGame build(int level) {
    final (discs, scrambled) = specs[level - 1];
    if (!scrambled) return HanoiGame(discs);
    final rng = Random(8800 + level * 17);
    while (true) {
      final game = HanoiGame.scrambled(
          [for (var d = 0; d < discs; d++) rng.nextInt(3)]);
      // Skip starts that are nearly finished.
      if (game.optimal >= 1 << (discs - 2)) return game;
    }
  }
}

const _discColors = [
  Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047),
  Color(0xFF1E88E5), Color(0xFF3949AB), Color(0xFF8E24AA), Color(0xFF6D4C41),
];

class TowerOfHanoiScreen extends StatefulWidget {
  const TowerOfHanoiScreen({super.key});
  @override
  State<TowerOfHanoiScreen> createState() => _TowerOfHanoiScreenState();
}

class _TowerOfHanoiScreenState extends State<TowerOfHanoiScreen> {
  int level = CampaignLevelBar.initialLevel('tower_of_hanoi');
  late HanoiGame game = HanoiLevels.build(level);

  int get discs => game.discs;
  int? from;
  (int, int)? hint;

  void _tap(int peg) {
    setState(() {
      hint = null;
      if (from == null) {
        if (game.pegs[peg].isNotEmpty) from = peg;
      } else if (from == peg) {
        from = null;
      } else if (game.canMove(from!, peg)) {
        game.move(from!, peg);
        from = null;
      } else if (game.pegs[peg].isNotEmpty) {
        from = peg;
      }
    });
  }

  void _selectPeg(int peg) {
    setState(() {
      hint = null;
      from = game.pegs[peg].isEmpty ? null : peg;
    });
  }

  void _dragPeg(int origin, int destination) {
    if (!game.canMove(origin, destination)) return;
    setState(() {
      game.move(origin, destination);
      from = null;
      hint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = game.solved
        ? 'Solved in ${game.moves} moves${game.moves == game.optimal ? ' — optimal!' : ' (best is ${game.optimal})'}'
        : 'Moves ${game.moves} · minimum ${game.optimal}';
    return GameScaffold(
      gameId: 'tower_of_hanoi',
      completed: game.solved,
      title: 'Tower of Hanoi',
      onNewGame: () => setState(() {
        game = HanoiLevels.build(level);
        from = null;
        hint = null;
      }),
      rules: 'Move the whole tower from the left peg to the right peg. Move '
          'one disc at a time, and never place a larger disc on a smaller one. '
          'The minimum number of moves is 2ⁿ − 1.\n\nThere are 20 levels with '
          '3 to 8 discs. Scrambled levels start with the discs spread over '
          'all three pegs; the goal is still the whole tower on the right '
          'peg, and the status line shows the minimum from that start. New '
          'game restarts the current level.',
      children: [
        CampaignLevelBar(
          gameId: 'tower_of_hanoi',
          level: level,
          solved: game.solved,
          onLevel: (value) => setState(() {
            level = value;
            game = HanoiLevels.build(level);
            from = null;
            hint = null;
          }),
          describe: (l) {
            final (d, scrambled) = HanoiLevels.specs[l - 1];
            return '$d discs${scrambled ? ', scrambled' : ''}';
          },
        ),
        StatusBanner(status, highlight: game.solved),
        SizedBox(
          height: 260,
          child: LayoutBuilder(builder: (context, box) {
            final pegW = box.maxWidth / 3;
            return GridBoardTouchArea(
              key: const ValueKey('hanoi_touch_board'),
              columns: 3,
              rows: 1,
              onTapCell: _tap,
              onDragStartCell: _selectPeg,
              onDragCell: _dragPeg,
              child: Row(children: [
                for (var p = 0; p < 3; p++)
                  Semantics(
                    label: 'Peg ${p + 1}, ${game.pegs[p].length} discs',
                    button: true,
                    selected: from == p,
                    onTap: () => _tap(p),
                    child: Container(
                    width: pegW,
                    color: from == p || hint?.$1 == p
                        ? colors.primaryContainer.withValues(alpha: .5)
                        : hint?.$2 == p ||
                                (from != null && game.canMove(from!, p))
                            ? colors.tertiaryContainer.withValues(alpha: .5)
                            : Colors.transparent,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      Container(width: 8, height: 230, color: const Color(0xFF6D4C41)),
                      Container(height: 10, color: const Color(0xFF6D4C41)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          for (final d in game.pegs[p].reversed)
                            Container(
                              width: pegW * (.25 + .7 * d / discs),
                              height: min(26, 200 / discs),
                              decoration: BoxDecoration(
                                color: _discColors[(d - 1) % _discColors.length],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: from == p && d == game.pegs[p].last ? colors.primary : Colors.black26,
                                    width: from == p && d == game.pegs[p].last ? 3 : 1),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                    ),
                  ),
              ]),
            );
          }),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: game.solved ? null : () => setState(() => hint = game.hint()),
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(hint == null ? 'Hint' : 'Move peg ${hint!.$1 + 1} → peg ${hint!.$2 + 1}'),
        ),
      ],
    );
  }
}
