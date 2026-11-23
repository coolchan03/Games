import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';

import 'game_tile.dart';

/// "Game of the day": one featured puzzle that is the same for everyone on a
/// given date and pays a one-time XP bonus the first time it is solved.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(dailyChallengeIdProvider);
    final done = ref.watch(dailyChallengeDoneProvider);
    if (id == null) return const SizedBox.shrink();
    final matches = allGamesMetadata.where((g) => g.id == id);
    if (matches.isEmpty) return const SizedBox.shrink();
    final game = matches.first;
    final title = L10nGameHelpers.getGameTitle(context, game.id);
    final theme = Theme.of(context);

    final statusText = done
        ? 'Completed today - come back tomorrow'
        : '+${engine.dailyChallengeBonusXp} bonus XP on your first solve';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignSystem.spaceLG, DesignSystem.spaceXS, DesignSystem.spaceLG, DesignSystem.spaceSM),
      child: Semantics(
        button: true,
        label: 'Daily challenge: $title. $statusText',
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
            side: BorderSide(
              color: done ? DesignSystem.success : DesignSystem.gold,
              width: 2,
            ),
          ),
          child: InkWell(
            key: const ValueKey('daily_challenge_card'),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
            onTap: () => launchGame(context, ref, game),
            child: Padding(
              padding: const EdgeInsets.all(DesignSystem.spaceSM + 2),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: game.color,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
                  ),
                  child: Icon(game.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: DesignSystem.spaceMD - 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DAILY CHALLENGE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: done ? DesignSystem.success : DesignSystem.warning,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium),
                      Text(statusText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  done ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                  size: 36,
                  color: done ? DesignSystem.success : DesignSystem.primary,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
