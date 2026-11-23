import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/game_providers.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'activity_widgets.dart';
import 'package:puzzle/ui/features/home/widgets/daily_progress_banner.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/tangible.dart';

class Achievement {
  final String title;
  final String description;
  final int requiredXp;
  final IconData icon;

  Achievement({
    required this.title,
    required this.description,
    required this.requiredXp,
    required this.icon,
  });
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static List<Achievement> getAchievements(AppLocalizations l10n) => [
    Achievement(
      title: l10n.achievementSeeker,
      description: l10n.achievementSeekerDesc,
      requiredXp: 100,
      icon: Icons.search_rounded,
    ),
    Achievement(
      title: l10n.achievementApprentice,
      description: l10n.achievementApprenticeDesc,
      requiredXp: 1000,
      icon: Icons.school_rounded,
    ),
    Achievement(
      title: l10n.achievementStrategist,
      description: l10n.achievementStrategistDesc,
      requiredXp: 5000,
      icon: Icons.psychology_rounded,
    ),
    Achievement(
      title: l10n.achievementElite,
      description: l10n.achievementEliteDesc,
      requiredXp: 10000,
      icon: Icons.military_tech_rounded,
    ),
    Achievement(
      title: l10n.achievementVeteran,
      description: l10n.achievementVeteranDesc,
      requiredXp: 25000,
      icon: Icons.shield_rounded,
    ),
    Achievement(
      title: l10n.achievementMaster,
      description: l10n.achievementMasterDesc,
      requiredXp: 50000,
      icon: Icons.workspace_premium_rounded,
    ),
    Achievement(
      title: l10n.achievementGrandmaster,
      description: l10n.achievementGrandmasterDesc,
      requiredXp: 100000,
      icon: Icons.diamond_rounded,
    ),
    Achievement(
      title: l10n.achievementLegend,
      description: l10n.achievementLegendDesc,
      requiredXp: 250000,
      icon: Icons.auto_awesome_rounded,
    ),
    Achievement(
      title: l10n.achievementMythic,
      description: l10n.achievementMythicDesc,
      requiredXp: 500000,
      icon: Icons.vignette_rounded,
    ),
    Achievement(
      title: l10n.achievementEternal,
      description: l10n.achievementEternalDesc,
      requiredXp: 1000000,
      icon: Icons.all_inclusive_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final achievements = StatsScreen.getAchievements(l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: false,
                  snap: false,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                    title: Text(
                      l10n.statsTitle,
                      style: theme.textTheme.displaySmall?.copyWith(
                        letterSpacing: 2.0,
                      ),
                    ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spaceLG,
                    DesignSystem.spaceMD,
                    DesignSystem.spaceLG,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) return _UserStatsCard(l10n: l10n);
                        if (index == 1) return const SizedBox(height: DesignSystem.spaceXL);
                        if (index == 2) return _CognitiveProfileCard(l10n: l10n);
                        if (index == 3) return const SizedBox(height: DesignSystem.spaceXL);
                        if (index == 4) {
                          return Text(
                            l10n.statsAchievements,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: DesignSystem.fontSizeLG,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.5,
                            ),
                          );
                        }
                        if (index == 5) return const SizedBox(height: DesignSystem.spaceMD);
                        final achievementIndex = index - 6;
                        if (achievementIndex == achievements.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: DesignSystem.spaceMD),
                            child: Text('MILESTONES',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: DesignSystem.fontSizeLG,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.5,
                                )),
                          );
                        }
                        if (achievementIndex == achievements.length + 1) {
                          return const SizedBox(height: DesignSystem.spaceMD);
                        }
                        if (achievementIndex > achievements.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: DesignSystem.spaceMD),
                            child: Consumer(builder: (context, ref, _) => MilestoneCard(
                                  milestone: engine.milestones[achievementIndex - achievements.length - 2],
                                  snapshot: ref.watch(progressSnapshotProvider),
                                )),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: DesignSystem.spaceMD),
                          child: _AchievementCard(achievement: achievements[achievementIndex], l10n: l10n),
                        );
                      },
                      childCount: 6 + achievements.length + 2 + engine.milestones.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserStatsCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UserStatsCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataNotifierProvider);
    final xp = userData.xp;
    final lp = engine.levelProgress(xp);
    final level = lp.level;
    final progress = lp.fraction;

    return Column(
      children: [
        _StreakTracker(l10n: l10n),
        const SizedBox(height: DesignSystem.spaceMD),
        const ActivityHeatmapCard(),
        const SizedBox(height: DesignSystem.spaceMD),
        const DailyProgressBanner(),
        const SizedBox(height: DesignSystem.spaceMD),
        TangibleContainer(
          color: DesignSystem.primary,
          padding: const EdgeInsets.all(DesignSystem.spaceLG),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                       fit: BoxFit.scaleDown,
                       alignment: Alignment.centerLeft,
                       child: Text(
                        l10n.statsLevel(level),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 42,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                       ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.statsMaintainStreak,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                   ),
                  ),
                  const SizedBox(width: DesignSystem.spaceMD),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMD),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignSystem.spaceXL),
              Stack(
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: DesignSystem.accentAmber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lp.isMax ? 'MAX LEVEL' : l10n.statsPercentToLevel((progress * 100).toInt(), level + 1),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSizeSM,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignSystem.spaceMD),
        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                label: l10n.statsTotalXp,
                value: '$xp',
                icon: Icons.bolt_rounded,
                color: DesignSystem.accentAmber,
              ),
            ),
            const SizedBox(width: DesignSystem.spaceMD),
            Expanded(
              child: _SmallStatCard(
                label: l10n.statsSolved,
                value: '${userData.totalSolved ?? 0}',
                icon: Icons.extension_rounded,
                color: DesignSystem.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakTracker extends ConsumerWidget {
  final AppLocalizations l10n;
  const _StreakTracker({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final log = ref.watch(activityLogProvider);
    final today = ref.watch(todayProvider);
    final superStreak = engine.currentActiveStreak(log, today);
    final loc = MaterialLocalizations.of(context);
    final weekStart = loc.firstDayOfWeekIndex == 0 ? DateTime.sunday : loc.firstDayOfWeekIndex;
    final startOfWeek = DateTime(today.year, today.month, today.day - ((today.weekday - weekStart + 7) % 7));

    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.statsWeeklyActivity,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: DesignSystem.fontSizeMD,
                    color: DesignSystem.mutedInk(context),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: DesignSystem.spaceSM),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: DesignSystem.gameOrange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    l10n.statsDayStreak(superStreak),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: DesignSystem.fontSizeMD,
                      color: DesignSystem.gameOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spaceMD),
          Row(
            children: List.generate(7, (index) {
              final dayDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + index);
              final dayLabel = loc.narrowWeekdays[dayDate.weekday % 7];
              final isToday = dayDate == today;
              final isSolved = (log[engine.dayKey(dayDate)] ?? 0) > 0;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 4.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSolved
                            ? DesignSystem.gameOrange
                            : (isToday
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.onSurface.withValues(alpha: 0.05)),
                        borderRadius:
                            BorderRadius.circular(DesignSystem.radiusSM),
                        border: isToday && !isSolved
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isSolved
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                            : Text(
                                dayLabel,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CognitiveProfileCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _CognitiveProfileCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalStats = ref.watch(categoryStatsProvider);
    final solvedStatsMap = ref.watch(solvedStatsProvider);
    
    final categories = totalStats.keys.where((k) => k != 'ALL').toList()..sort();

    final categoryColors = {
      'LOGIC': DesignSystem.gameTeal,
      'MATH': DesignSystem.gameAmber,
      'MEMORY': DesignSystem.gameRose,
      'SPATIAL': DesignSystem.gameIndigo,
      'ATTENTION': DesignSystem.gamePurple,
      'WORD': DesignSystem.gameGreen,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statsCognitiveProfile,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: DesignSystem.fontSizeLG,
            color: colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: DesignSystem.spaceMD),
        TangibleContainer(
          padding: const EdgeInsets.all(DesignSystem.spaceMD),
          child: Column(
            children: categories.map((cat) {
              final solved = solvedStatsMap[cat] ?? 0;
              final total = (totalStats[cat] ?? 1).clamp(1, 1 << 30);
              final color = categoryColors[cat] ?? DesignSystem.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: DesignSystem.spaceMD),
                child: _CategoryProgressItem(
                  category: cat,
                  solved: solved,
                  total: total,
                  color: color,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryProgressItem extends StatelessWidget {
  final String category;
  final int solved;
  final int total;
  final Color color;

  const _CategoryProgressItem({
    required this.category,
    required this.solved,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (solved / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$solved / $total',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: DesignSystem.fontSizeSM,
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
               child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: DesignSystem.mutedInk(context),
                  letterSpacing: 0.5,
                ),
               ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 32,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends ConsumerWidget {
  final Achievement achievement;
  final AppLocalizations l10n;

  const _AchievementCard({required this.achievement, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(userDataNotifierProvider.select((d) => d.xp));
    final isUnlocked = xp >= achievement.requiredXp;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? DesignSystem.accentAmber.withValues(alpha: 0.2)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(DesignSystem.radiusSM),
              border: Border.all(
                color: isUnlocked
                    ? DesignSystem.accentAmber.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              achievement.icon,
              size: 32,
              color: isUnlocked
                  ? DesignSystem.accentAmber
                  : DesignSystem.mutedInk(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: DesignSystem.fontSizeLG,
                    color: isUnlocked
                        ? colorScheme.onSurface
                        : DesignSystem.mutedInk(context),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? colorScheme.onSurface.withValues(alpha: 0.6)
                        : DesignSystem.mutedInk(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(
              Icons.check_circle_rounded,
              size: 32,
              color: DesignSystem.success,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DesignSystem.radiusXS),
              ),
              child: Text(
                l10n.statsLocked,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: DesignSystem.mutedInk(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
