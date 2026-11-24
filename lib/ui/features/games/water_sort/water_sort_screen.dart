import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../utils/l10n_game_helpers.dart';
import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import '../common/level_kit.dart';
import 'water_sort_engine.dart';
import 'water_sort_levels.dart';

/// Water Sort with 30 numbered levels, endless random levels, undo, hints and
/// trap detection. Every level is winnable; when the player's own pours make
/// the position unwinnable the solver proves it and offers Undo.
class WaterSortScreen extends StatefulWidget {
  const WaterSortScreen({super.key});

  @override
  State<WaterSortScreen> createState() => _WaterSortScreenState();
}

class _WaterSortScreenState extends State<WaterSortScreen> {
  static const _id = 'water_sort';

  late int level = CampaignLevelBar.initialLevel(_id, count: WaterSortLevels.count);
  bool randomMode = false;
  late WaterSortLevel lvl;
  late Tubes tubes;
  final List<Tubes> history = [];
  int moves = 0;
  int? selected;
  ({int from, int to})? hint;
  bool trapped = false;
  String? notice;
  final monitor = TrapMonitor<Tubes>(WaterSortPuzzle(), maxNodes: 25000);

  @override
  void initState() {
    super.initState();
    _load(level);
  }

  void _load(int n, {bool resume = true}) {
    level = n;
    randomMode = false;
    lvl = WaterSortLevels.build(n);
    tubes = WaterSortLevels.copy(lvl.tubes);
    moves = 0;
    if (resume) {
      final saved = CampaignLevelBar.restoreActive(_id, n);
      final restored = saved == null ? null : WaterSortLevels.decode(saved, lvl);
      if (restored != null) {
        tubes = restored.$1;
        moves = restored.$2;
      }
    }
    _reset();
  }

  void _loadRandom() {
    randomMode = true;
    lvl = WaterSortLevels.random(level);
    tubes = WaterSortLevels.copy(lvl.tubes);
    moves = 0;
    _reset();
  }

  void _reset() {
    history.clear();
    selected = null;
    hint = null;
    notice = null;
    trapped = !WaterSortLevels.isSolved(tubes) && monitor.isTrapped(tubes);
  }

  bool get solved => WaterSortLevels.isSolved(tubes);

  void _tap(int index) {
    if (solved) return;
    HapticFeedback.selectionClick();
    setState(() {
      hint = null;
      notice = null;
      final from = selected;
      if (from == null) {
        if (tubes[index].isNotEmpty) selected = index;
        return;
      }
      selected = null;
      if (from == index || !WaterSortLevels.canPour(tubes[from], tubes[index])) {
        return;
      }
      history.add(WaterSortLevels.copy(tubes));
      WaterSortLevels.pour(tubes[from], tubes[index]);
      moves++;
      trapped = !solved && monitor.isTrapped(tubes);
    });
  }

  void _undo() {
    if (history.isEmpty) return;
    setState(() {
      tubes = history.removeLast();
      moves = moves > 0 ? moves - 1 : 0;
      selected = null;
      hint = null;
      notice = null;
      trapped = !solved && monitor.isTrapped(tubes);
    });
  }

  void _hint() {
    if (solved) return;
    final next = monitor.hint(tubes);
    setState(() {
      selected = null;
      if (next == null) {
        hint = null;
        notice = trapped
            ? 'No winning line from here. Undo to go back.'
            : 'This position is too big to analyse - try your own plan.';
        return;
      }
      // Find the pour that leads to the suggested position.
      final puzzle = WaterSortPuzzle();
      final target = puzzle.key(next);
      int? from, to;
      for (var i = 0; i < tubes.length && from == null; i++) {
        for (var j = 0; j < tubes.length; j++) {
          if (i == j || !WaterSortLevels.canPour(tubes[i], tubes[j])) continue;
          final probe = WaterSortLevels.copy(tubes);
          WaterSortLevels.pour(probe[i], probe[j]);
          if (puzzle.key(probe) == target) {
            from = i;
            to = j;
            break;
          }
        }
      }
      hint = from == null ? null : (from: from, to: to!);
      notice = hint == null ? 'Try a different pour.' : null;
      if (hint != null) selected = hint!.from;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final stars = starsForPar(moves, lvl.par);
    final banner = solved
        ? 'Solved in $moves moves! ${'★' * stars}'
        : trapped
            ? 'Stuck: no pour can finish this. Undo or restart.'
            : 'Moves: $moves  ·  Par ${lvl.par}';
    return GameScaffold(
      gameId: _id,
      title: L10nGameHelpers.getGameTitle(context, _id),
      confirmNewGame: moves > 0 && !solved,
      completed: solved,
      deadEnd: trapped,
      deadEndMessage:
          'No sequence of pours can sort the tubes from here. Undo a few '
          'moves, or restart the level.',
      onUndo: history.isEmpty ? null : _undo,
      onNewGame: () => setState(() => randomMode ? _loadRandom() : _load(level, resume: false)),
      rules: 'Pour colours between tubes until every tube holds one colour. '
          'You can pour onto an empty tube or onto the same colour, as long as '
          'there is room. Tap a tube, then the tube to pour into.\n\n'
          'There are ${WaterSortLevels.count} levels (3 to 8 colours) and endless random levels; '
          'every one is winnable from the start. Hint shows a safe pour, and '
          'the game tells you when your moves have made the puzzle unwinnable.',
      children: [
        if (!randomMode)
          CampaignLevelBar(
            gameId: _id,
            level: level,
            count: WaterSortLevels.count,
            solved: solved,
            onLevel: (n) => setState(() => _load(n)),
            describe: WaterSortLevels.describe,
            activeState: trapped ? null : WaterSortLevels.encode(tubes, moves),
            result: CampaignResult(
              score: moves,
              stars: stars,
              label: (m) => '$m moves',
            ),
          )
        else
          Row(children: [
            const Icon(Icons.casino_rounded),
            const SizedBox(width: 8),
            const Expanded(child: Text('Random level')),
            TextButton(
              onPressed: () => setState(() => _load(level, resume: false)),
              child: const Text('Back to levels'),
            ),
          ]),
        Row(children: [
          Expanded(child: StatusBanner(banner, highlight: solved)),
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
            tooltip: 'Random level',
            onPressed: () => setState(_loadRandom),
            icon: const Icon(Icons.casino_outlined),
          ),
        ]),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(notice!, style: TextStyle(color: s.error)),
          ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, box) {
          final perRow = tubes.length <= 5 ? tubes.length : (tubes.length + 1) ~/ 2;
          const gap = 12.0;
          final width = ((box.maxWidth - gap * (perRow + 1)) / perRow).clamp(34.0, 64.0);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: 36,
            children: [
              for (var i = 0; i < tubes.length; i++)
                Semantics(
                  button: true,
                  label: 'Tube ${i + 1}, ${tubes[i].length} of ${WaterSortLevels.capacity}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tap(i),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: _TubeWidget(
                        colors: tubes[i],
                        isSelected: selected == i,
                        isHintTarget: hint?.to == i,
                        width: width,
                        height: 150,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _TubeWidget extends StatelessWidget {
  final List<int> colors;
  final bool isSelected;
  final bool isHintTarget;
  final double width;
  final double height;

  const _TubeWidget({
    required this.colors,
    required this.isSelected,
    this.isHintTarget = false,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tubeRadius = width / 2;
    final outerRadius = BorderRadius.vertical(
      bottom: Radius.circular(tubeRadius),
      top: const Radius.circular(6),
    );

    final depth = isSelected ? 8.0 : 4.0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      transform: isSelected ? Matrix4.translationValues(0.0, -20.0, 0.0) : Matrix4.identity(),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Shadow / Depth Layer
          Positioned(
            top: depth,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: outerRadius,
              ),
            ),
          ),
          // Main Tube Body
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: outerRadius,
              border: Border.all(
                color: isHintTarget
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: isHintTarget ? 4.0 : 2.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(tubeRadius - 2),
                top: const Radius.circular(4),
              ),
              child: Stack(
                children: [
                  // Water segments
                  Column(
                    verticalDirection: VerticalDirection.up,
                    children: [
                      for (int i = 0; i < WaterSortLevels.capacity; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: i < colors.length ? WaterSortEngine.availableColors[colors[i] % WaterSortEngine.availableColors.length] : Colors.transparent,
                              border: i < colors.length 
                                ? Border(
                                    top: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                  )
                                : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Glass Gloss/Shine
                  Positioned(
                    left: width * 0.15,
                    top: 10,
                    bottom: 10,
                    width: width * 0.12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tube Rim (Top)
          Positioned(
            top: -2,
            child: Container(
              width: width + 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5), width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

