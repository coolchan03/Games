import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';

class HanoiGame {
  HanoiGame(this.discs) : pegs = [List.generate(discs, (i) => discs - i), [], []];
  final int discs;
  final List<List<int>> pegs;
  int moves = 0;

  int get optimal => (1 << discs) - 1;
  bool get solved => pegs[2].length == discs;

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
  int discs = 4;
  late HanoiGame game = HanoiGame(discs);
  int? from;
  (int, int)? hint;

  void _tap(int peg) {
    setState(() {
      hint = null;
      if (from == null) {
        if (game.pegs[peg].isNotEmpty) from = peg;
      } else {
        game.move(from!, peg);
        from = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = game.solved
        ? 'Solved in ${game.moves} moves${game.moves == game.optimal ? ' — optimal!' : ' (best is ${game.optimal})'}'
        : 'Moves ${game.moves} · minimum ${game.optimal}';
    return GameScaffold(
      title: 'Tower of Hanoi',
      onNewGame: () => setState(() {
        game = HanoiGame(discs);
        from = null;
      }),
      rules: 'Move the whole tower from the left peg to the right peg. Move '
          'one disc at a time, and never place a larger disc on a smaller one. '
          'The minimum number of moves is 2ⁿ − 1.',
      children: [
        SegmentedButton<int>(
          segments: [for (final n in const [3, 4, 5, 6, 7, 8]) ButtonSegment(value: n, label: Text('$n'))],
          selected: {discs},
          onSelectionChanged: (s) => setState(() {
            discs = s.first;
            game = HanoiGame(discs);
            from = null;
          }),
        ),
        StatusBanner(status, highlight: game.solved),
        SizedBox(
          height: 260,
          child: LayoutBuilder(builder: (context, box) {
            final pegW = box.maxWidth / 3;
            return Row(children: [
              for (var p = 0; p < 3; p++)
                GestureDetector(
                  onTap: () => _tap(p),
                  child: Container(
                    width: pegW,
                    color: from == p || hint?.$1 == p
                        ? colors.primaryContainer.withValues(alpha: .5)
                        : hint?.$2 == p
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
            ]);
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
