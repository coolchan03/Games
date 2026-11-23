import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/tangible.dart';

/// GitHub-style grid of the last weeks of play, plus streak summary.
class ActivityHeatmapCard extends ConsumerWidget {
  const ActivityHeatmapCard({super.key, this.weeks = 15});
  final int weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final log = ref.watch(activityLogProvider);
    final today = ref.watch(todayProvider);
    final loc = MaterialLocalizations.of(context);
    // firstDayOfWeekIndex: 0 = Sunday. DateTime weekdays: 1 = Monday .. 7 = Sunday.
    final weekStart = loc.firstDayOfWeekIndex == 0 ? DateTime.sunday : loc.firstDayOfWeekIndex;
    final grid = engine.activityGrid(log, today, weeks: weeks, weekStartsOn: weekStart);
    final maxCount = log.values.fold<int>(1, (m, v) => v > m ? v : m);
    final current = engine.currentActiveStreak(log, today);
    final best = engine.longestActiveStreak(log);
    final total = log.values.fold<int>(0, (a, b) => a + b);

    Color shade(int? count) {
      if (count == null) return Colors.transparent;
      if (count == 0) return theme.colorScheme.outline.withValues(alpha: 0.35);
      final t = (count / maxCount).clamp(0.0, 1.0);
      return Color.lerp(DesignSystem.primary.withValues(alpha: 0.35), DesignSystem.primary, t)!;
    }

    // Day labels aligned to the localized week start.
    final labels = [
      for (var i = 0; i < 7; i++) loc.narrowWeekdays[(weekStart % 7 + i) % 7]
    ];

    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      semanticsLabel:
          'Activity: $total puzzles in the last $weeks weeks, current streak $current days, best streak $best days',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('ACTIVITY',
                style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: DesignSystem.fontSizeMD,
                    color: DesignSystem.mutedInk(context),
                    letterSpacing: 1.0)),
          ),
          Text('Last $weeks weeks', style: theme.textTheme.labelMedium),
        ]),
        const SizedBox(height: DesignSystem.spaceSM),
        LayoutBuilder(builder: (context, c) {
          const labelWidth = 16.0, gap = 3.0;
          final cell = ((c.maxWidth - labelWidth - gap * weeks) / weeks).clamp(8.0, 22.0);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: labelWidth,
              child: Column(children: [
                for (final l in labels)
                  SizedBox(
                    height: cell + gap,
                    child: Text(l, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
                  ),
              ]),
            ),
            for (final week in grid)
              Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Column(children: [
                  for (final count in week)
                    Container(
                      width: cell,
                      height: cell,
                      margin: const EdgeInsets.only(bottom: gap),
                      decoration: BoxDecoration(
                        color: shade(count),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ]),
              ),
          ]);
        }),
        const SizedBox(height: DesignSystem.spaceSM),
        Wrap(spacing: DesignSystem.spaceMD, runSpacing: DesignSystem.spaceXS, children: [
          _Stat(icon: Icons.local_fire_department_rounded, label: 'Current', value: '$current d'),
          _Stat(icon: Icons.emoji_events_rounded, label: 'Best', value: '$best d'),
          _Stat(icon: Icons.event_available_rounded, label: 'Active days', value: '${log.length}'),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: DesignSystem.gameOrange),
      const SizedBox(width: 4),
      Text('$label ', style: theme.textTheme.labelMedium),
      Text(value, style: theme.textTheme.labelLarge),
    ]);
  }
}

/// A behaviour milestone with a progress bar toward its target.
class MilestoneCard extends StatelessWidget {
  const MilestoneCard({super.key, required this.milestone, required this.snapshot});
  final engine.Milestone milestone;
  final engine.ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = milestone.isUnlocked(snapshot);
    final accent = unlocked ? DesignSystem.accentAmber : DesignSystem.mutedInk(context);
    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      semanticsLabel:
          '${milestone.title}: ${milestone.description}. ${unlocked ? 'Unlocked' : '${milestone.progress(snapshot)} of ${milestone.target}'}',
      child: Row(children: [
        Icon(unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            size: 32, color: accent),
        const SizedBox(width: DesignSystem.spaceMD),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(milestone.title, style: theme.textTheme.titleSmall),
            Text(milestone.description, style: theme.textTheme.bodySmall),
            if (!unlocked) ...[
              const SizedBox(height: DesignSystem.spaceXS),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: milestone.fraction(snapshot),
                  minHeight: 6,
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(width: DesignSystem.spaceSM),
        unlocked
            ? const Icon(Icons.check_circle_rounded, color: DesignSystem.success, size: 28)
            : Text('${milestone.progress(snapshot)}/${milestone.target}',
                style: theme.textTheme.labelLarge),
      ]),
    );
  }
}
