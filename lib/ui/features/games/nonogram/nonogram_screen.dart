import 'dart:async';
import 'dart:math' as math;

import "package:puzzle/l10n/app_localizations.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/design_system.dart';
import '../../../../utils/haptic_feedback.dart';
import '../common/campaign_progress.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/juice/game_scaffold.dart';
import 'nonogram_provider.dart';
import 'nonogram_engine.dart';
import 'nonogram_touch.dart';
import '../common/grid_board_touch_area.dart';

class NonogramScreen extends ConsumerStatefulWidget {
  const NonogramScreen({super.key});

  @override
  ConsumerState<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends ConsumerState<NonogramScreen> {
  bool _isMarkMode = false;
  final Set<int> _completedLevels = CampaignProgress.load(
    'nonogram', maxLevel: NonogramEngine.campaignLevelCount,
  );

  void _levelFinished(int level) {
    _completedLevels.add(level);
    unawaited(CampaignProgress.save('nonogram', _completedLevels));
    HapticFeedbackUtil.victory();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Level $level complete!'),
        content: Text('You solved level $level of '
            '${NonogramEngine.campaignLevelCount}.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(nonogramNotifierProvider.notifier).reset();
            },
            child: const Text('Replay'),
          ),
          if (level < NonogramEngine.campaignLevelCount)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(nonogramNotifierProvider.notifier)
                    .loadLevel(level + 1);
              },
              child: const Text('Next level'),
            ),
        ],
      ),
    );
  }

  void _tapCell(int cell, int size) {
    HapticFeedbackUtil.selectionClick();
    ref.read(nonogramNotifierProvider.notifier)
        .toggleCell(cell ~/ size, cell % size, _isMarkMode);
  }

  void _dragCells(int from, int to, int size) {
    final cells = nonogramStrokeCells(from, to, size);
    if (cells.length < 2) return;
    HapticFeedbackUtil.selectionClick();
    ref.read(nonogramNotifierProvider.notifier)
        .paintCells(cells, _isMarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(nonogramNotifierProvider);

    ref.listen(nonogramNotifierProvider, (previous, next) {
      if (next.hasValue && next.value!.isSolved &&
          !(previous?.value?.isSolved ?? false)) {
        _levelFinished(next.value!.levelNumber);
      }
    });

    return GameScaffold(
      title: l10n.nonogramTitle.toUpperCase(),
      subtitle: l10n.nonogramSubtitle,
      actions: [
        TangibleButton(
          color: colorScheme.surface,
          shadowColor: colorScheme.outline,
          onTap: () {
            HapticFeedbackUtil.mediumImpact();
            ref.read(nonogramNotifierProvider.notifier).reset();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.refresh_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
        ),
      ],
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.nonogramText((err).toString()))),
        data: (nonogramState) => LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                const SizedBox(height: DesignSystem.spaceSM),
                _buildStatusHeader(nonogramState),
                const SizedBox(height: DesignSystem.spaceSM),
                _buildLevelPicker(nonogramState),
                const SizedBox(height: DesignSystem.spaceSM),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spaceMD),
                    child: LayoutBuilder(
                      builder: (context, available) {
                        const rowClueWidth = 48.0;
                        const columnClueHeight = 48.0;
                        final side = math.max(
                          0.0,
                          math.min(
                            available.maxWidth - rowClueWidth,
                            available.maxHeight - columnClueHeight,
                          ),
                        );
                        if (side <= 0) return const SizedBox.shrink();

                        return Center(
                          child: SizedBox(
                            width: rowClueWidth + side,
                            height: columnClueHeight + side,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: columnClueHeight,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: rowClueWidth),
                                      for (var c = 0;
                                          c < nonogramState.size;
                                          c++)
                                        Expanded(
                                          child: _buildColClue(
                                              nonogramState.colClues[c]),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: side,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: rowClueWidth,
                                        child: Column(
                                          children: [
                                            for (var r = 0;
                                                r < nonogramState.size;
                                                r++)
                                              Expanded(
                                                child: _buildRowClue(
                                                    nonogramState.rowClues[r]),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: side,
                                        child: GridBoardTouchArea(
                                          key: const ValueKey(
                                              'nonogram_touch_board'),
                                          columns: nonogramState.size,
                                          rows: nonogramState.size,
                                          onTapCell: (cell) =>
                                              _tapCell(cell, nonogramState.size),
                                          onDragCell: (from, to) => _dragCells(
                                            from,
                                            to,
                                            nonogramState.size,
                                          ),
                                          child: Column(
                                            children: [
                                              for (var r = 0;
                                                  r < nonogramState.size;
                                                  r++)
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      for (var c = 0;
                                                          c < nonogramState.size;
                                                          c++)
                                                        Expanded(
                                                          child: NonogramCell(
                                                            key: ValueKey('nonogram_cell_' +
                                                                r.toString() + '_' + c.toString()),
                                                            row: r,
                                                            col: c,
                                                            isMarkMode:
                                                                _isMarkMode,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: DesignSystem.spaceMD),
                _buildControls(),
                const SizedBox(height: DesignSystem.spaceLG),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelPicker(NonogramState state) {
    final notifier = ref.read(nonogramNotifierProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceMD),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous level',
            onPressed: state.levelNumber > 1
                ? () => notifier.loadLevel(state.levelNumber - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: DropdownButton<int>(
              key: const ValueKey('nonogram_level_selector'),
              isExpanded: true,
              value: state.levelNumber,
              items: [
                for (var level = 1;
                    level <= NonogramEngine.campaignLevelCount;
                    level++)
                  DropdownMenuItem(
                    value: level,
                    child: Text(
                      '${_completedLevels.contains(level) ? '[Done] ' : ''}'
                      'Level $level - ${NonogramEngine.sizeForLevel(level)}x'
                      '${NonogramEngine.sizeForLevel(level)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (level) {
                if (level != null) notifier.loadLevel(level);
              },
            ),
          ),
          IconButton(
            tooltip: 'Next level',
            onPressed: state.levelNumber < NonogramEngine.campaignLevelCount
                ? () => notifier.loadLevel(state.levelNumber + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(NonogramState state) {
    return TangibleContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: DesignSystem.accentBerry.withValues(alpha: 0.1),
      radius: DesignSystem.radiusFull,
      depth: 2,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_on_rounded, size: 16, color: DesignSystem.accentBerry),
          SizedBox(width: 8),
          Text(
            'NONOGRAM',
            style: TextStyle(
              color: DesignSystem.accentBerry,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColClue(List<int> clues) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int clue in clues)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  clue.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRowClue(List<int> clues) {
    return Container(
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int clue in clues)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  clue.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceXL),
      child: Row(
        children: [
          Expanded(
            child: TangibleButton(
              onTap: () {
                HapticFeedbackUtil.selectionClick();
                setState(() => _isMarkMode = false);
              },
              color: !_isMarkMode ? DesignSystem.accentBerry : Theme.of(context).colorScheme.surface,
              shadowColor: !_isMarkMode ? DesignSystem.accentBerry.withValues(alpha: 0.8) : Theme.of(context).colorScheme.outline,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.square_rounded, color: !_isMarkMode ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'FILL',
                    style: TextStyle(color: !_isMarkMode ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: TangibleButton(
              onTap: () {
                HapticFeedbackUtil.selectionClick();
                setState(() => _isMarkMode = true);
              },
              color: _isMarkMode ? DesignSystem.accentBerry : Theme.of(context).colorScheme.surface,
              shadowColor: _isMarkMode ? DesignSystem.accentBerry.withValues(alpha: 0.8) : Theme.of(context).colorScheme.outline,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: _isMarkMode ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'MARK',
                    style: TextStyle(color: _isMarkMode ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NonogramCell extends ConsumerWidget {
  final int row;
  final int col;
  final bool isMarkMode;

  const NonogramCell({
    super.key,
    required this.row,
    required this.col,
    required this.isMarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(nonogramNotifierProvider.select(
        (s) => s.value?.grid[row][col] ?? 0));
    final cellDescription =
        value == 1 ? 'filled' : value == 2 ? 'marked empty' : 'unknown';

    // Normal finger interactions belong to the board surface so a slow
    // drag does not toggle both the origin and its destination.
    // Accessibility users retain per-cell activate actions.
    return Semantics(
      label: 'Row ' + (row + 1).toString() + ', column ' +
          (col + 1).toString() + ', ' + cellDescription,
      button: true,
      onTap: () => ref.read(nonogramNotifierProvider.notifier)
          .toggleCell(row, col, isMarkMode),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: TangibleContainer(
          depth: value == 1 ? 0 : 2.0,
          radius: 4,
          padding: EdgeInsets.zero,
          color: value == 1
              ? DesignSystem.accentBerry
              : Theme.of(context).colorScheme.surface,
          child: Center(
            child: value == 2
                ? FittedBox(
                    child: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
