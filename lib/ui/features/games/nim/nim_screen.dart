import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';

/// Nim: take any number of objects from one row. In the normal game the
/// player who takes the last object wins; in misère the one who takes it
/// loses. The computer plays perfectly on Hard using nim-sums.
class NimGame {
  NimGame(this.rows, {this.misere = false});
  final List<int> rows;
  final bool misere;
  int turn = 0;

  List<int> snapshot() => [turn, ...rows];

  static NimGame? restore(List<int> saved, {required bool misere}) {
    if (saved.length != 5 || saved.first < 0 || saved.first > 1) return null;
    const initial = [1, 3, 5, 7];
    for (var i = 0; i < 4; i++) {
      if (saved[i + 1] < 0 || saved[i + 1] > initial[i]) return null;
    }
    final game = NimGame(saved.skip(1).toList(), misere: misere);
    game.turn = saved.first;
    return game;
  }

  bool get over => rows.every((r) => r == 0);

  /// Winner once over: the player who did NOT move last in misère.
  int get winner => misere ? turn : 1 - turn;

  void take(int row, int n) {
    rows[row] -= n;
    turn = 1 - turn;
  }

  (int, int) bestMove(Random rng, int level) {
    final nonEmpty = [for (var i = 0; i < rows.length; i++) if (rows[i] > 0) i];
    if (level == 0 || (level == 1 && rng.nextDouble() < .35)) {
      final r = nonEmpty[rng.nextInt(nonEmpty.length)];
      return (r, rng.nextInt(rows[r]) + 1);
    }
    final big = rows.where((r) => r > 1).length;
    if (misere && big <= 1) {
      // Endgame of misère: leave an odd number of single-object rows.
      final r = rows.indexWhere((x) => x > 1);
      final ones = rows.where((x) => x == 1).length;
      if (r >= 0) {
        return (r, ones.isOdd ? rows[r] : rows[r] - 1);
      }
      return (nonEmpty.first, 1);
    }
    final x = rows.fold(0, (a, b) => a ^ b);
    if (x != 0) {
      for (var i = 0; i < rows.length; i++) {
        final target = rows[i] ^ x;
        if (target < rows[i]) return (i, rows[i] - target);
      }
    }
    final r = nonEmpty[rng.nextInt(nonEmpty.length)];
    return (r, 1);
  }
}

class NimScreen extends StatefulWidget {
  const NimScreen({super.key});
  @override
  State<NimScreen> createState() => _NimScreenState();
}

class _NimScreenState extends State<NimScreen> {
  final rng = Random();
  bool misere = false;
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late NimGame game = _restoreOrStart();
  (int, int)? pick; // (row, count from the right)
  bool thinking = false;
  int _generation = 0;

  NimGame _create() => NimGame([1, 3, 5, 7], misere: misere);

  NimGame _restoreOrStart() {
    final saved = CampaignProgress.loadActive('nim', 1, maxLength: 8);
    if (saved != null && saved.length == 8 &&
        (saved[0] == 0 || saved[0] == 1) &&
        (saved[1] == 0 || saved[1] == 1) &&
        saved[2] >= 0 && saved[2] < AiLevel.values.length) {
      final restored = NimGame.restore(saved.skip(3).toList(),
        misere: saved[0] == 1);
      if (restored != null) {
        misere = saved[0] == 1;
        vsComputer = saved[1] == 1;
        level = AiLevel.values[saved[2]];
        return restored;
      }
    }
    return _create();
  }

  void _save() => unawaited(CampaignProgress.saveActive('nim', 1, [
    misere ? 1 : 0, vsComputer ? 1 : 0, level.index,
    ...game.snapshot(),
  ]));

  @override
  void initState() {
    super.initState();
    if (vsComputer && game.turn == 1 && !game.over) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_computerTurn(_generation));
      });
    }
  }

  void _newGame() {
    setState(() {
      _generation++;
      game = _create();
      pick = null;
      thinking = false;
    });
    _save();
  }

  Future<void> _take() async {
    final p = pick;
    if (p == null || thinking || game.over ||
        p.$1 < 0 || p.$1 >= game.rows.length ||
        p.$2 < 1 || p.$2 > game.rows[p.$1]) return;
    final generation = _generation;
    if (vsComputer && game.turn != 0) return;
    setState(() {
      game.take(p.$1, p.$2);
      pick = null;
    });
    _save();
    if (vsComputer && !game.over) await _computerTurn(generation);
  }

  Future<void> _computerTurn(int generation) async {
    if (thinking || !vsComputer || game.turn != 1 || game.over) return;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || generation != _generation || !vsComputer || game.over ||
        game.turn != 1) return;
    setState(() {
      final (r, n) = game.bestMove(rng, level.index);
      game.take(r, n);
      thinking = false;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final names = vsComputer ? ['You', 'Computer'] : ['Player 1', 'Player 2'];
    final status = game.over
        ? '${names[game.winner]} win${game.winner == 0 && vsComputer ? '' : 's'}!'
        : thinking
            ? 'Computer is thinking…'
            : '${names[game.turn]}: tap matches in one row, then Take';
    return GameScaffold(
      gameId: 'nim',
      completed: game.over && (game.winner == 0 || !vsComputer),
      title: 'Nim',
      onNewGame: _newGame,
      rules: 'Players take turns removing any number of matches from a single '
          'row. In normal play whoever takes the last match wins; in misère '
          'play whoever takes it loses. Tap a match: it and every match to '
          'its right in that row are selected. Hard plays perfectly.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Normal (last wins)')),
            ButtonSegment(value: true, label: Text('Misère (last loses)')),
          ],
          selected: {misere},
          onSelectionChanged: (s) {
            misere = s.first;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: game.over),
        for (var r = 0; r < game.rows.length; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < game.rows[r]; k++)
                GestureDetector(
                  onTap: thinking || game.over || (vsComputer && game.turn == 1)
                      ? null : () => setState(() => pick = (r, game.rows[r] - k)),
                  child: Container(
                    width: 18,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: pick != null && pick!.$1 == r && k >= game.rows[r] - pick!.$2
                          ? colors.primary.withValues(alpha: .35)
                          : const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border(top: BorderSide(color: const Color(0xFFD32F2F), width: 14)),
                    ),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: pick == null || thinking || game.over ? null : _take,
          child: Text(pick == null ? 'Take' : 'Take ${pick!.$2} from row ${pick!.$1 + 1}'),
        ),
      ],
    );
  }
}
