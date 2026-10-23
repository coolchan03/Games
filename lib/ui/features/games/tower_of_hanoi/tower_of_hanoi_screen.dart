import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';

class HanoiGame {
  HanoiGame(this.discs) : pegs = [List.generate(discs, (i) => discs - i), [], []];
  final int discs;
  final List<List<int>> pegs;
  int moves = 0;
  final List<(int, int)> history = [];

  /// Each disc has a peg index; peg lists are rebuilt in descending order.
  List<int> snapshot() => [
    moves,
    for (var d = 1; d <= discs; d++)
      pegs.indexWhere((peg) => peg.contains(d)),
  ];

  bool restore(List<int> data) {
    if (data.length != discs + 1 || data[0] < 0 ||
        data.skip(1).any((peg) => peg < 0 || peg > 2)) return false;
    for (final peg in pegs) { peg.clear(); }
    for (var d = discs; d >= 1; d--) { pegs[data[d]].add(d); }
    moves = data.first;
    history.clear();
    return true;
  }

  bool get canUndo => history.isNotEmpty;
  void undo() {
    if (!canUndo) return;
    final (from, to) = history.removeLast();
    pegs[from].add(pegs[to].removeLast());
    moves--;
  }

  int get optimal => (1 << discs) - 1;
  bool get solved => pegs[2].length == discs;

  bool canMove(int from, int to) => from >= 0 && from < 3 &&
      to >= 0 && to < 3 && from != to && pegs[from].isNotEmpty &&
      (pegs[to].isEmpty || pegs[to].last > pegs[from].last);

  bool move(int from, int to) {
    if (!canMove(from, to)) return false;
    pegs[to].add(pegs[from].removeLast());
    history.add((from, to));
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
  // Keep the original four-disc default for existing players and tests.
  int discs = switch (CampaignProgress.selectedLevel('tower_of_hanoi', count: 6)) {
    2 => 3,
    3 => 5,
    4 => 6,
    5 => 7,
    6 => 8,
    _ => 4,
  };
  late HanoiGame game = _load();
  int? from;
  (int, int)? hint;

  HanoiGame _load() {
    final result = HanoiGame(discs);
    final saved = CampaignProgress.loadActive('tower_of_hanoi', discs,
      maxLength: discs + 1);
    if (saved != null) result.restore(saved);
    return result;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'tower_of_hanoi', discs, game.snapshot(),
  ));

  void _restart() {
    setState(() { game = HanoiGame(discs); from = null; hint = null; });
    _save();
  }

  void _undo() {
    if (!game.canUndo) return;
    setState(() { game.undo(); from = null; hint = null; });
    _save();
  }

  void _tap(int peg) {
    setState(() {
      hint = null;
      if (from == null) {
        if (game.pegs[peg].isNotEmpty) from = peg;
      } else if (from == peg) {
        from = null;
      } else if (game.canMove(from!, peg)) {
        game.move(from!, peg);
        _save();
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
      _save();
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
      onNewGame: _restart,
      rules: 'Move the whole tower from the left peg to the right peg. Move '
          'one disc at a time, and never place a larger disc on a smaller one. '
          'The minimum number of moves is 2ⁿ − 1.',
      children: [
        SegmentedButton<int>(
          segments: [for (final n in const [3, 4, 5, 6, 7, 8]) ButtonSegment(value: n, label: Text('$n'))],
          selected: {discs},
          onSelectionChanged: (s) {
            setState(() {
              discs = s.first;
              game = _load();
              from = null;
              hint = null;
            });
            final selected = switch (discs) {
              3 => 2,
              5 => 3,
              6 => 4,
              7 => 5,
              8 => 6,
              _ => 1,
            };
            unawaited(CampaignProgress.saveSelected('tower_of_hanoi', selected));
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
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: game.canUndo ? _undo : null,
            icon: const Icon(Icons.undo), label: const Text('Undo'),
          ),
          OutlinedButton.icon(
            onPressed: game.solved ? null : () => setState(() => hint = game.hint()),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(hint == null ? 'Hint' : 'Move peg ${hint!.$1 + 1} → peg ${hint!.$2 + 1}'),
          ),
        ]),
      ],
    );
  }
}
