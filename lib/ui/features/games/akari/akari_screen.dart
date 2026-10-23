import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';

import '../../../../../providers/user_providers.dart';
import '../../../../../utils/haptic_feedback.dart';
import '../../../core/juice/game_scaffold.dart';
import '../../../../widgets/game_completion_dialog.dart';
import '../../../../widgets/tangible.dart';
import '../../../../utils/design_system.dart';
import '../common/campaign_progress.dart';
import 'akari_campaign_data.dart';
import 'akari_provider.dart';

class AkariScreen extends ConsumerStatefulWidget {
  const AkariScreen({super.key});

  @override
  ConsumerState<AkariScreen> createState() => _AkariScreenState();
}

class _AkariScreenState extends ConsumerState<AkariScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(akariNotifierProvider.notifier).initGame();
    });
  }

  void _showCompletionDialog(int levelNumber) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameCompletionDialog(
        title: l10n.akariWinTitle,
        message: l10n.akariWinMessage,
        isVictory: true,
        onHome: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
        onPlayAgain: () {
          Navigator.of(dialogContext).pop();
          final notifier = ref.read(akariNotifierProvider.notifier);
          if (levelNumber < AkariCampaignData.levelCount) {
            notifier.loadLevel(levelNumber + 1);
          } else {
            notifier.restartLevel();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(akariNotifierProvider);
    final notifier = ref.read(akariNotifierProvider.notifier);

    ref.listen(akariNotifierProvider, (previous, next) {
      if (next.isVictory && !(previous?.isVictory ?? false)) {
        HapticFeedbackUtil.victory();
        ref.read(gameStreakNotifierProvider.notifier).completeGame('akari');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCompletionDialog(next.levelNumber);
        });
      }
    });

    if (state.isLoading) {
      return GameScaffold(
        title: l10n.akariTitle,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GameScaffold(
      title: l10n.akariTitle,
      subtitle: l10n.akariSubtitle,
      actions: [
        TangibleButton(
          color: colorScheme.surface,
          shadowColor: colorScheme.outline,
          padding: const EdgeInsets.all(8),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.howToPlay),
              content: Text(l10n.akariHowToPlay),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.gotIt),
                ),
              ],
            ),
          ),
          child: Icon(Icons.help_outline, color: colorScheme.onSurface),
        ),
      ],
      body: Column(
        children: [
          _levelControls(state, notifier),
          Expanded(
            child: LayoutBuilder(builder: (context, bounds) {
              final side = math.max(0.0, math.min(
                bounds.maxWidth - DesignSystem.spaceLG * 2,
                bounds.maxHeight - DesignSystem.spaceMD * 2,
              ));
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.onSurface, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final cellSize = constraints.maxWidth / state.grid.length;
                      return Column(
                        children: List.generate(state.grid.length, (r) => Row(
                          children: List.generate(state.grid.length, (c) =>
                            _buildCell(state, notifier, r, c, cellSize)),
                        )),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _levelControls(AkariState state, AkariNotifier notifier) {
    final complete = CampaignProgress.load(
      'akari',
      maxLevel: AkariCampaignData.levelCount,
    );
    if (state.isVictory) complete.add(state.levelNumber);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous level',
              onPressed: state.levelNumber > 1
                  ? () => notifier.loadLevel(state.levelNumber - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(child: Text(
              'Level ${state.levelNumber}/${AkariCampaignData.levelCount} · '
              '${state.grid.length}×${state.grid.length} · '
              '${complete.length} completed',
              textAlign: TextAlign.center,
            )),
            IconButton(
              tooltip: 'Next level',
              onPressed: state.levelNumber < AkariCampaignData.levelCount
                  ? () => notifier.loadLevel(state.levelNumber + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Restart level',
              onPressed: notifier.restartLevel,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        SizedBox(
          height: 43,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AkariCampaignData.levelCount,
            itemBuilder: (context, index) {
              final level = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(complete.contains(level) ? '$level ✓' : '$level'),
                  selected: state.levelNumber == level,
                  onSelected: (_) => notifier.loadLevel(level),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    AkariState state,
    AkariNotifier notifier,
    int r,
    int c,
    double size,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final val = state.grid[r][c];
    final isBulb = state.bulbs[r][c];
    final isLit = state.lit[r][c];

    if (val >= -1) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: val >= 0 ? Center(
          child: Text('$val', style: TextStyle(
            color: colorScheme.surface,
            fontWeight: FontWeight.bold,
            fontSize: (size * .45).clamp(11.0, 24.0).toDouble(),
          )),
        ) : null,
      );
    }
    return GestureDetector(
      onTap: () => notifier.toggleBulb(r, c),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isLit
              ? DesignSystem.accentAmber.withValues(alpha: 0.3)
              : colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: isBulb ? Icon(
            Icons.lightbulb,
            color: DesignSystem.accentAmber,
            size: (size * .55).clamp(14.0, 30.0).toDouble(),
          ) : null,
        ),
      ),
    );
  }
}
