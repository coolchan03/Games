import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kakuro_provider.dart';
import 'kakuro_engine.dart';
import 'kakuro_campaign_data.dart';
import '../common/campaign_progress.dart';
import '../../../../../providers/user_providers.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../../utils/design_system.dart';
import '../../../../utils/haptic_feedback.dart';
import '../../../core/juice/game_scaffold.dart';

class KakuroScreen extends ConsumerWidget {
  const KakuroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kakuroNotifierProvider);
    final notifier = ref.read(kakuroNotifierProvider.notifier);

    ref.listen(kakuroNotifierProvider, (previous, next) {
      if (next.isSolved && !(previous?.isSolved ?? false)) {
        HapticFeedbackUtil.victory();
        ref.read(gameStreakNotifierProvider.notifier)
            .completeGame('kakuro', xpAmount: 25);
        notifier.flushProgress().then((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => GameCompletionDialog(
              title: L10nGameHelpers.getGameTitle(context, 'kakuro'),
              message: AppLocalizations.of(context)!.kakuroMessage,
              onHome: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              onPlayAgain: () {
                Navigator.of(dialogContext).pop();
                notifier.newGame();
              },
            ),
          );
        });
      }
    });

    return GameScaffold(
      title: L10nGameHelpers.getGameTitle(context, 'kakuro'),
      subtitle: 'Kakuro level ${state.level.levelNumber}/${KakuroCampaignData.levelCount}',
      actions: [
        IconButton(
          tooltip: 'How to play Kakuro',
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('How to Play Kakuro'),
              content: const Text(
                'Fill each white cell with a digit from 1 to 9. '
                'Each clue gives the sum of the consecutive white cells '
                'to its right or below. Digits may not repeat within a run. '
                'Shaded starter digits cannot be changed. '
                'Complete levels and resume unfinished puzzles offline.',
              ),
              actions: [TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Got it'),
              )],
            ),
          ),
          icon: const Icon(Icons.help_outline),
        ),
        IconButton(
          tooltip: 'Restart Kakuro level',
          onPressed: notifier.restartLevel,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, bounds) {
          final landscape = bounds.maxWidth > bounds.maxHeight;
          if (landscape) {
            final controlsWidth = min(300.0, bounds.maxWidth * .38);
            return Row(children: [
              Expanded(child: LayoutBuilder(builder: (context, size) {
                final boardSize = min(size.maxWidth - 8, size.maxHeight - 8);
                return Center(child: _buildBoard(
                  context, state, notifier, max(1.0, boardSize),
                ));
              })),
              SizedBox(
                width: controlsWidth,
                child: SingleChildScrollView(child: Column(children: [
                  _campaignControls(context, state, notifier),
                  _buildInputKeyboard(context, state, notifier),
                ])),
              ),
            ]);
          }
          return Column(children: [
            _campaignControls(context, state, notifier),
            Expanded(child: LayoutBuilder(builder: (context, size) {
              final boardSize = min(size.maxWidth - 16, size.maxHeight - 12);
              return Center(child: _buildBoard(
                context, state, notifier, max(1.0, boardSize),
              ));
            })),
            _buildInputKeyboard(context, state, notifier),
          ]);
        },
      ),
    );
  }

  Widget _buildBoard(BuildContext context, KakuroState state,
      KakuroNotifier notifier, double boardSize) {
    return TangibleContainer(
      color: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.outline,
      depth: 3.0,
      radius: DesignSystem.radiusLG,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        key: const Key('kakuro-board'),
        width: max(1.0, boardSize - 8),
        height: max(1.0, boardSize - 8),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: state.level.size,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: state.level.size * state.level.size,
          itemBuilder: (context, index) {
            final row = index ~/ state.level.size;
            final col = index % state.level.size;
            return _buildCell(context, state.level.grid[row][col],
                state, notifier);
          },
        ),
      ),
    );
  }

  Widget _campaignControls(BuildContext context, KakuroState state,
      KakuroNotifier notifier) {
    final level = state.level.levelNumber;
    final completed = CampaignProgress.load('kakuro', maxLevel: 20);
    if (state.isSolved) completed.add(level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            tooltip: 'Previous Kakuro level',
            onPressed: level == 1 ? null : () => notifier.loadLevel(level - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton(
            onPressed: () => _showLevels(context, notifier, completed, level),
            child: Text('Level $level / ${KakuroCampaignData.levelCount}'),
          ),
          IconButton(
            tooltip: 'Next Kakuro level',
            onPressed: level == KakuroCampaignData.levelCount
                ? null : () => notifier.loadLevel(level + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        Text('${completed.length} / 20 completed',
            style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }

  void _showLevels(BuildContext context, KakuroNotifier notifier,
      Set<int> completed, int current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: min(380.0, MediaQuery.sizeOf(sheetContext).height * .65),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: KakuroCampaignData.levelCount,
            itemBuilder: (context, index) {
              final number = index + 1;
              return Semantics(
                label: 'Kakuro level $number',
                child: ChoiceChip(
                  label: Text(completed.contains(number) ? '$number ✓' : '$number'),
                  selected: current == number,
                  onSelected: (_) {
                    Navigator.of(sheetContext).pop();
                    notifier.loadLevel(number);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    KakuroCell cell,
    KakuroState state,
    KakuroNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (cell.isBlock) {
      return TangibleContainer(
        color: colorScheme.outline.withValues(alpha: 0.4),
        shadowColor: Colors.transparent,
        depth: 0.0,
        radius: DesignSystem.radiusSM,
        child: const SizedBox.shrink(),
      );
    }

    if (cell.isClue) {
      return TangibleContainer(
        color: colorScheme.outline.withValues(alpha: 0.15),
        shadowColor: Colors.transparent,
        depth: 0.0,
        radius: DesignSystem.radiusSM,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _KakuroCluePainter(colorScheme.onSurface),
              ),
            ),
            if (cell.hClue != null)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 0.5,
                    child: FittedBox(
                      alignment: Alignment.topRight,
                      child: Text(
                        '${cell.hClue}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: DesignSystem.accentEmerald,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (cell.vClue != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 0.5,
                    child: FittedBox(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '${cell.vClue}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: DesignSystem.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // White cell
    final val = state.currentValues[Point(cell.c, cell.r)];
    final isSelected = state.selectedRow == cell.r && state.selectedCol == cell.c;

    Color cellColor = colorScheme.surface;
    Color? shadowColor = colorScheme.outline;
    double depth = 2.0;

    if (cell.isGiven) {
      cellColor = colorScheme.surfaceContainerHighest;
      shadowColor = colorScheme.outline.withValues(alpha: 0.4);
    }
    if (isSelected) {
      cellColor = DesignSystem.primary;
      shadowColor = DesignSystem.primary.withValues(alpha: 0.5);
      depth = 2.0;
    }

    return GestureDetector(
      onTap: cell.isGiven ? null : () {
        HapticFeedbackUtil.lightImpact();
        notifier.selectCell(cell.r, cell.c);
      },
      child: TangibleContainer(
        color: cellColor,
        shadowColor: shadowColor,
        depth: depth,
        radius: DesignSystem.radiusSM,
        padding: EdgeInsets.zero,
        child: Center(
          child: FittedBox(
            child: Text(
              val != null ? '$val' : '',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white
                    : cell.isGiven ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputKeyboard(BuildContext context, KakuroState state, KakuroNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildButton(int val) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TangibleButton(
            onTap: () {
              HapticFeedbackUtil.lightImpact();
              notifier.setCellValue(val);
            },
            color: colorScheme.surface,
            shadowColor: colorScheme.outline,
            padding: const EdgeInsets.symmetric(vertical: 8),
            radius: DesignSystem.radiusSM,
            child: Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 1; i <= 5; i++) buildButton(i),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 6; i <= 9; i++) buildButton(i),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TangibleButton(
                    onTap: () {
                      HapticFeedbackUtil.lightImpact();
                      notifier.setCellValue(null);
                    },
                    color: colorScheme.surface,
                    shadowColor: colorScheme.outline,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    radius: DesignSystem.radiusSM,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        color: DesignSystem.error,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KakuroCluePainter extends CustomPainter {
  final Color color;

  _KakuroCluePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
