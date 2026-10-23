import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
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
  final List<List<int>> _history = [];

  bool get canUndo => _history.isNotEmpty;
  void undo() {
    if (!canUndo) return;
    tiles = _history.removeLast();
    moves--;
  }

  List<int> snapshot() => [moves, ...tiles];
  bool restore(List<int> data) {
    if (data.length != n * n + 1 || data.first < 0) return false;
    final state = data.skip(1).toList();
    if (state.toSet().length != n * n ||
        state.any((v) => v < 1 || v > n * n)) return false;
    moves = data.first;
    tiles = state;
    _history.clear();
    return true;
  }

  bool get solved {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  /// Rotates the block whose top-left cell is (x, y).
  void rotate(int x, int y, bool clockwise, {bool count = true}) {
    if (x < 0 || y < 0 || x + block > n || y + block > n) return;
    if (count) _history.add(List<int>.of(tiles));
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

class TwiddleScreen extends StatefulWidget {
  const TwiddleScreen({super.key});
  @override
  State<TwiddleScreen> createState() => _TwiddleScreenState();
}

class _TwiddleScreenState extends State<TwiddleScreen> {
  static const _configs = [(3, 2), (4, 2), (4, 3), (5, 3)];
  int configIndex = CampaignProgress.selectedLevel('twiddle', count: 4) - 1;
  (int, int) get config => _configs[configIndex];
  late TwiddleGame game = _load();
  bool clockwise = true;

  TwiddleGame _load() {
    final result = TwiddleGame(n: config.$1, block: config.$2);
    final data = CampaignProgress.loadActive('twiddle', configIndex + 1,
        maxLength: config.$1 * config.$1 + 1);
    if (data != null) result.restore(data);
    return result;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'twiddle', configIndex + 1, game.snapshot(),
  ));

  void _newGame() {
    setState(() => game = TwiddleGame(n: config.$1, block: config.$2));
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
    final n = game.n, b = game.block;
    final anchors = n - b + 1;
    return GameScaffold(
      gameId: 'twiddle',
      completed: game.solved,
      title: 'Twiddle',
      onNewGame: _newGame,
      rules: 'Put the numbers back in order, reading left to right and top '
          'to bottom. Tap one of the round handles to rotate the block of '
          'tiles around it; choose clockwise or anticlockwise below. From '
          'Simon Tatham\'s Portable Puzzle Collection. Unfinished boards resume offline.',
      children: [
        SegmentedButton<(int, int)>(
          segments: const [
            ButtonSegment(value: (3, 2), label: Text('3×3')),
            ButtonSegment(value: (4, 2), label: Text('4×4')),
            ButtonSegment(value: (4, 3), label: Text('4×4 big')),
            ButtonSegment(value: (5, 3), label: Text('5×5')),
          ],
          selected: {config},
          onSelectionChanged: (s) {
            setState(() {
              configIndex = _configs.indexOf(s.first);
              game = _load();
            });
            unawaited(CampaignProgress.saveSelected('twiddle', configIndex + 1));
          },
        ),
        Row(children: [
          Expanded(child: StatusBanner(
            game.solved ? 'Solved in ${game.moves} moves!' : 'Moves: ${game.moves}',
            highlight: game.solved,
          )),
          IconButton(
            tooltip: 'Undo', onPressed: game.canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
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
                        onTap: game.solved ? null : () {
                          setState(() => game.rotate(x, y, clockwise));
                          _save();
                        },
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
