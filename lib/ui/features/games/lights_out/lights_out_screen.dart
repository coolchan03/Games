import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../utils/l10n_game_helpers.dart';
import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'lights_out_levels.dart';

/// Lights Out with 20 numbered levels (3x3 up to 7x7), endless random levels,
/// undo and an exact hint. Every board is proven clearable by the solver, so a
/// player can never be handed or trapped in an impossible position: presses
/// always keep the board in the solvable set.
class LightsOutScreen extends StatefulWidget {
  const LightsOutScreen({super.key});

  @override
  State<LightsOutScreen> createState() => _LightsOutScreenState();
}

class _LightsOutScreenState extends State<LightsOutScreen> {
  static const _id = 'lights_out';

  late int level = CampaignLevelBar.initialLevel(_id, count: LightsOutLevels.count);
  bool randomMode = false;
  late LightsOutLevel lvl;
  late List<bool> lights;
  final List<List<bool>> history = [];
  int presses = 0;
  int? hintCell;

  @override
  void initState() {
    super.initState();
    _load(level);
  }

  int get n => lvl.size;
  bool get solved => !lights.any((on) => on);

  void _load(int number, {bool resume = true}) {
    level = number;
    randomMode = false;
    lvl = LightsOutLevels.build(number);
    lights = [...lvl.lights];
    presses = 0;
    if (resume) {
      final saved = CampaignLevelBar.restoreActive(_id, number, maxLength: 64);
      // [presses, 0/1 per cell]; only trusted when it is still clearable.
      if (saved != null && saved.length == lvl.lights.length + 1) {
        final board = [for (final v in saved.sublist(1)) v == 1];
        if (LightsOutSolver.isSolvable(n, board)) {
          lights = board;
          presses = saved[0] < 0 ? 0 : saved[0];
        }
      }
    }
    history.clear();
    hintCell = null;
  }

  void _loadRandom() {
    randomMode = true;
    lvl = LightsOutLevels.random(level);
    lights = [...lvl.lights];
    presses = 0;
    history.clear();
    hintCell = null;
  }

  void _press(int cell) {
    if (solved) return;
    HapticFeedback.lightImpact();
    setState(() {
      history.add([...lights]);
      lights = LightsOutSolver.press(n, lights, cell);
      presses++;
      hintCell = null;
    });
  }

  void _undo() {
    if (history.isEmpty) return;
    setState(() {
      lights = history.removeLast();
      presses = presses > 0 ? presses - 1 : 0;
      hintCell = null;
    });
  }

  void _hint() {
    final solution = LightsOutSolver.solve(n, lights);
    setState(() => hintCell = solution == null || solution.isEmpty ? null : solution.first);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = solved ? 0 : (LightsOutSolver.solve(n, lights)?.length ?? 0);
    final stars = starsForPar(presses, lvl.par);
    return GameScaffold(
      gameId: _id,
      title: L10nGameHelpers.getGameTitle(context, _id),
      completed: solved,
      confirmNewGame: presses > 0 && !solved,
      onNewGame: () => setState(() => randomMode ? _loadRandom() : _load(level, resume: false)),
      rules: 'Tap a light to toggle it and its four neighbours. Turn every '
          'light off to win.\n\nThere are ${LightsOutLevels.count} levels, from 3×3 '
          'to 7×7, plus endless random boards. Every board can be cleared; the '
          'par is the fewest presses possible, and Hint shows a press from a '
          'best solution.',
      children: [
        if (!randomMode)
          CampaignLevelBar(
            gameId: _id,
            level: level,
            count: LightsOutLevels.count,
            solved: solved,
            onLevel: (v) => setState(() => _load(v)),
            describe: LightsOutLevels.describe,
            activeState: [presses, for (final on in lights) on ? 1 : 0],
            result: CampaignResult(score: presses, stars: stars, label: (m) => '$m presses'),
          )
        else
          Row(children: [
            const Icon(Icons.casino_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text('Random ${LightsOutLevels.describe(level)} board')),
            TextButton(
              onPressed: () => setState(() => _load(level, resume: false)),
              child: const Text('Back to levels'),
            ),
          ]),
        Row(children: [
          Expanded(
            child: StatusBanner(
              solved
                  ? 'Cleared in $presses presses! ${'★' * stars}'
                  : 'Presses: $presses  ·  Par ${lvl.par}  ·  Left ≥ $remaining',
              highlight: solved,
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: history.isEmpty || solved ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton.filledTonal(
            tooltip: 'Hint',
            onPressed: solved ? null : _hint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton.filledTonal(
            tooltip: 'Random board',
            onPressed: () => setState(_loadRandom),
            icon: const Icon(Icons.casino_outlined),
          ),
        ]),
        const SizedBox(height: 8),
        LandscapeBoard(
          child: AspectRatio(
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
                    child: Semantics(
                      button: true,
                      label: 'Row ${i ~/ n + 1}, column ${i % n + 1}, ${lights[i] ? 'on' : 'off'}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _press(i),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: lights[i] ? Colors.amber.shade600 : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: hintCell == i
                                ? Border.all(color: colors.primary, width: 4)
                                : null,
                          ),
                          child: lights[i]
                              ? Icon(Icons.lightbulb_rounded,
                                  color: Colors.white, size: cell * .5)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
        ),
      ],
    );
  }
}
