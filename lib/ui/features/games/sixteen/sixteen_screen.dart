import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';

/// Sixteen (after Simon Tatham's Portable Puzzle Collection, sixteen.c,
/// MIT): restore the grid by cyclically shifting whole rows and columns.
class SixteenGame {
  SixteenGame({this.n = 4, Random? random}) {
    tiles = List.generate(n * n, (i) => i + 1);
    final rng = random ?? Random();
    do {
      for (var k = 0; k < n * n * 3; k++) {
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
  final List<List<int>> _history = [];

  bool get canUndo => _history.isNotEmpty;
  void undo() {
    if (!canUndo) return;
    tiles = _history.removeLast();
    moves--;
  }

  /// Retains only the tile permutation and move count, not the random seed.
  List<int> snapshot() => [moves, ...tiles];

  bool restore(List<int> saved) {
    if (saved.length != n * n + 1 || saved.first < 0) return false;
    final permutation = saved.skip(1).toList();
    if (permutation.toSet().length != n * n ||
        permutation.any((v) => v < 1 || v > n * n)) return false;
    moves = saved.first;
    tiles = permutation;
    _history.clear();
    return true;
  }

  bool get solved {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  void shiftRow(int r, int by, {bool count = true}) {
    if (r < 0 || r >= n || by.abs() != 1) return;
    if (count) _history.add(List<int>.of(tiles));
    final row = [for (var c = 0; c < n; c++) tiles[r * n + c]];
    for (var c = 0; c < n; c++) {
      tiles[r * n + (c + by) % n] = row[c];
    }
    if (count) moves++;
  }

  void shiftCol(int c, int by, {bool count = true}) {
    if (c < 0 || c >= n || by.abs() != 1) return;
    if (count) _history.add(List<int>.of(tiles));
    final col = [for (var r = 0; r < n; r++) tiles[r * n + c]];
    for (var r = 0; r < n; r++) {
      tiles[((r + by) % n) * n + c] = col[r];
    }
    if (count) moves++;
  }
}

class SixteenScreen extends StatefulWidget {
  const SixteenScreen({super.key});
  @override
  State<SixteenScreen> createState() => _SixteenScreenState();
}

class _SixteenScreenState extends State<SixteenScreen> {
  int n = switch (CampaignProgress.selectedLevel('sixteen', count: 3)) {
    2 => 3,
    3 => 5,
    _ => 4,
  };
  late SixteenGame game = _load();

  int get _modeId => n == 4 ? 1 : n == 3 ? 2 : 3;

  SixteenGame _load() {
    final result = SixteenGame(n: n);
    final saved = CampaignProgress.loadActive(
      'sixteen', _modeId, maxLength: n * n + 1,
    );
    if (saved != null) result.restore(saved);
    return result;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'sixteen', _modeId, game.snapshot(),
  ));

  void _newGame() {
    setState(() => game = SixteenGame(n: n));
    _save();
  }

  void _undo() {
    if (!game.canUndo) return;
    setState(game.undo);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget arrow(IconData icon, VoidCallback onTap) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: game.solved ? null : () {
            setState(onTap);
            _save();
          },
          icon: Icon(icon, size: 20),
        );
    return GameScaffold(
      gameId: 'sixteen',
      completed: game.solved,
      title: 'Sixteen',
      onNewGame: _newGame,
      rules: 'Put the numbers back in order. Use the arrows around the edge '
          'to slide a whole row or column one step; the tile pushed off one '
          'end comes back on the other. From Simon Tatham\'s Portable Puzzle '
          'Collection. Your unfinished board is saved offline.',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3×3')),
            ButtonSegment(value: 4, label: Text('4×4')),
            ButtonSegment(value: 5, label: Text('5×5')),
          ],
          selected: {n},
          onSelectionChanged: (s) {
            setState(() {
              n = s.first;
              game = _load();
            });
            unawaited(CampaignProgress.saveSelected('sixteen', _modeId));
          },
        ),
        Row(children: [
          Expanded(child: StatusBanner(
            game.solved ? 'Solved in ${game.moves} moves!' : 'Moves: ${game.moves}',
            highlight: game.solved,
          )),
          IconButton(
            tooltip: 'Undo',
            onPressed: game.canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        LayoutBuilder(builder: (context, box) {
          final cell = (box.maxWidth - 80) / n;
          return Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 40),
              for (var c = 0; c < n; c++) SizedBox(width: cell, child: arrow(Icons.arrow_upward, () => game.shiftCol(c, -1))),
              const SizedBox(width: 40),
            ]),
            for (var r = 0; r < n; r++)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 40, child: arrow(Icons.arrow_back, () => game.shiftRow(r, -1))),
                for (var c = 0; c < n; c++)
                  Container(
                    width: cell - 6,
                    height: cell - 6,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: game.tiles[r * n + c] == r * n + c + 1 ? colors.primaryContainer : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('${game.tiles[r * n + c]}', style: TextStyle(fontSize: cell * .35, fontWeight: FontWeight.bold)),
                  ),
                SizedBox(width: 40, child: arrow(Icons.arrow_forward, () => game.shiftRow(r, 1))),
              ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 40),
              for (var c = 0; c < n; c++) SizedBox(width: cell, child: arrow(Icons.arrow_downward, () => game.shiftCol(c, 1))),
              const SizedBox(width: 40),
            ]),
          ]);
        }),
      ],
    );
  }
}
