import "package:puzzle/l10n/app_localizations.dart";
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'word_search_provider.dart';
import 'word_search_engine.dart';
import '../common/campaign_progress.dart';
import '../../../../../providers/user_providers.dart';
import '../../../../../utils/design_system.dart';
import '../../../../../utils/haptic_feedback.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../core/juice/game_scaffold.dart';

class WordSearchScreen extends ConsumerStatefulWidget {
  const WordSearchScreen({super.key});

  @override
  ConsumerState<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends ConsumerState<WordSearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(wordSearchNotifierProvider.notifier).initGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(wordSearchNotifierProvider);
    final notifier = ref.read(wordSearchNotifierProvider.notifier);

    ref.listen(wordSearchNotifierProvider, (previous, next) {
      if (next.isSolved && !(previous?.isSolved ?? false)) {
        HapticFeedbackUtil.victory();
        _showVictoryDialog(context, ref);
      }
    });

    return GameScaffold(
      title: l10n.wordSearchTitle.toUpperCase(),
      subtitle: l10n.wordSearchSubtitle,
      actions: [
        TangibleButton(
          color: colorScheme.surface,
          shadowColor: colorScheme.outline,
          onTap: () {
            HapticFeedbackUtil.mediumImpact();
            notifier.restartLevel();
          },
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.refresh_rounded, size: 20, color: colorScheme.onSurface),
        ),
      ],
      body: state.board == null
          ? const Center(child: CircularProgressIndicator(color: DesignSystem.primary))
          : Column(
              children: [
                _buildCampaignControls(state, notifier),
                Expanded(
                  child: LayoutBuilder(builder: (context, bounds) => Center(
                    child: _buildGrid(state, notifier,
                        min(bounds.maxHeight, bounds.maxWidth)),
                  )),
                ),
                Flexible(
                  child: SingleChildScrollView(child: _buildWordList(state)),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  Widget _buildCampaignControls(WordSearchState state, WordSearchNotifier notifier) {
    final completed = CampaignProgress.load('word_search');
    if (state.isSolved) completed.add(state.levelNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(tooltip: 'Previous level', onPressed: state.levelNumber > 1
              ? () => notifier.loadLevel(state.levelNumber - 1) : null,
              icon: const Icon(Icons.chevron_left)),
          Expanded(child: Text('Level ${state.levelNumber}/${WordSearchEngine.campaignLevelCount} - ${WordSearchEngine.campaignThemes[state.levelNumber - 1]}',
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(tooltip: 'Next level', onPressed: state.levelNumber < WordSearchEngine.campaignLevelCount
              ? () => notifier.loadLevel(state.levelNumber + 1) : null,
              icon: const Icon(Icons.chevron_right)),
          IconButton(tooltip: 'Restart level', onPressed: () => notifier.restartLevel(),
              icon: const Icon(Icons.restart_alt)),
        ]),
        Text('${completed.length}/${WordSearchEngine.campaignLevelCount} completed'),
        SizedBox(height: 42, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: WordSearchEngine.campaignLevelCount,
          itemBuilder: (context, index) {
            final level = index + 1;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                label: Text(completed.contains(level) ? '$level ✓' : '$level'),
                selected: level == state.levelNumber,
                onSelected: (_) => notifier.loadLevel(level),
              ));
          },
        )),
      ]),
    );
  }

  Widget _buildWordList(WordSearchState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.symmetric(horizontal: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORDS TO FIND',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: state.board!.words.map((word) {
              final isFound = word.isFound;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFound 
                      ? DesignSystem.success.withValues(alpha: 0.1) 
                      : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusXS),
                  border: Border.all(
                    color: isFound ? DesignSystem.success : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  word.word.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isFound ? FontWeight.w500 : FontWeight.w900,
                    color: isFound 
                        ? DesignSystem.success 
                        : Theme.of(context).colorScheme.onSurface,
                    decoration: isFound ? TextDecoration.lineThrough : null,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(WordSearchState state, WordSearchNotifier notifier, double maxHeight) {
    final board = state.board!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceLG),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxHeight, maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: 1,
          child: TangibleContainer(
            color: Theme.of(context).colorScheme.onSurface,
            shadowColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            radius: DesignSystem.radiusMD,
            depth: 4.0,
            padding: const EdgeInsets.all(3.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMD - 4),
              child: LayoutBuilder(builder: (context, bounds) {
                // Use the actual letter grid dimensions, not the outer bezel.
                final cellSize = bounds.maxWidth / board.size;
                return Stack(
                  children: [
                    _buildFoundLines(state, cellSize),
                    _buildSelectionLine(state, cellSize),
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: board.size,
                      ),
                      itemCount: board.size * board.size,
                      itemBuilder: (context, index) {
                        final x = index % board.size;
                        final y = index ~/ board.size;
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: FittedBox(
                              child: Text(
                                board.grid[y][x],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        key: const Key('word-search-grid-gesture'),
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) {
                          HapticFeedbackUtil.gameInteraction();
                          _handlePanUpdate(
                            details.localPosition, cellSize, board.size, notifier, true,
                          );
                        },
                        onPanUpdate: (details) => _handlePanUpdate(
                          details.localPosition, cellSize, board.size, notifier, false,
                        ),
                        onPanEnd: (_) {
                          HapticFeedbackUtil.selectionClick();
                          notifier.endSelection();
                        },
                        onPanCancel: notifier.cancelSelection,
                        onTapUp: (_) => notifier.cancelSelection(),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePanUpdate(Offset localPos, double cellSize, int size, WordSearchNotifier notifier, bool isStart) {
    int x = (localPos.dx / cellSize).floor();
    int y = (localPos.dy / cellSize).floor();

    if (x >= 0 && x < size && y >= 0 && y < size) {
      if (isStart) {
        notifier.startSelection(x, y);
      } else {
        notifier.updateSelection(x, y);
      }
    }
  }

  Widget _buildFoundLines(WordSearchState state, double cellSize) {
    return Positioned.fill(
      child: Stack(
        children: state.board!.words.where((w) => w.isFound).map((w) {
          return _buildLine(w.positions, cellSize, DesignSystem.success.withValues(alpha: 0.3));
        }).toList(),
      ),
    );
  }

  Widget _buildSelectionLine(WordSearchState state, double cellSize) {
    if (state.selection.isEmpty) return const SizedBox.shrink();
    return _buildLine(state.selection, cellSize, DesignSystem.primary.withValues(alpha: 0.3));
  }

  Widget _buildLine(List<Point<int>> positions, double cellSize, Color color) {
    if (positions.isEmpty) return const SizedBox.shrink();
    
    final start = positions.first;
    final end = positions.last;

    return Positioned.fill(child: CustomPaint(
      painter: LinePainter(
        start: Offset((start.x + 0.5) * cellSize, (start.y + 0.5) * cellSize),
        end: Offset((end.x + 0.5) * cellSize, (end.y + 0.5) * cellSize),
        color: color,
        strokeWidth: cellSize * 0.7,
      ),
    ));
  }

  void _showVictoryDialog(BuildContext context, WidgetRef ref) async {
    await ref.read(wordSearchNotifierProvider.notifier).flushProgress();
    if (!context.mounted) return;
    await ref.read(gameStreakNotifierProvider.notifier).completeGame('word_search');

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          final notifier = ref.read(wordSearchNotifierProvider.notifier);
          final level = ref.read(wordSearchNotifierProvider).levelNumber;
          if (level < WordSearchEngine.campaignLevelCount) {
            notifier.loadLevel(level + 1);
          } else {
            notifier.restartLevel();
          }
          Navigator.of(context).pop();
        },
        message: AppLocalizations.of(context)!.wordSearchMessage,
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  LinePainter({required this.start, required this.end, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) => 
      oldDelegate.start != start || oldDelegate.end != end || oldDelegate.color != color;
}
