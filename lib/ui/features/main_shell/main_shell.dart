import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import '../../../domain/progress_engine.dart' as engine;
import '../../../providers/progress_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../home/home_screen.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';

/// Top-level navigation: a bottom [NavigationBar] on phones and a
/// [NavigationRail] on wider screens. Tabs are built lazily and kept alive in
/// an [IndexedStack] so scroll position, search text and filters survive
/// switching tabs.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const int _statsTab = 0, _homeTab = 1, _settingsTab = 2;

  int _selectedIndex = _homeTab;
  final Set<int> _visited = {_homeTab};
  Timer? _dayCheckTimer;
  DateTime _lastCheckedDate = engine.dayOf(DateTime.now());

  Widget _screen(int index) => switch (index) {
        _statsTab => const StatsScreen(),
        _settingsTab => const SettingsScreen(),
        _ => const HomeScreen(),
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDay());
    _dayCheckTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkDayChange());
  }

  void _refreshDay() {
    if (!mounted) return;
    ref.read(todayProvider.notifier).state = engine.dayOf(DateTime.now());
    ref.read(gameStreakNotifierProvider.notifier).refreshStatus();
  }

  void _checkDayChange() {
    final today = engine.dayOf(DateTime.now());
    if (today != _lastCheckedDate) {
      _lastCheckedDate = today;
      _refreshDay();
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastCheckedDate = engine.dayOf(DateTime.now());
      _refreshDay();
    }
  }

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  void _showMilestones(List<engine.Milestone> unlocked) {
    if (unlocked.isEmpty || !mounted) return;
    final text = unlocked.length == 1
        ? 'Achievement unlocked: ${unlocked.first.title}'
        : 'Achievements unlocked: ${unlocked.map((m) => m.title).join(', ')}';
    // Routes pushed above the shell (the game itself) own their own messenger
    // scope; the root messenger shows this when the player returns.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.emoji_events_rounded, color: DesignSystem.gold),
          const SizedBox(width: DesignSystem.spaceSM),
          Expanded(child: Text(text)),
        ]),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: DesignSystem.gold,
          onPressed: () => _select(_statsTab),
        ),
      ));
    ref.read(milestoneToastProvider.notifier).state = const [];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<engine.Milestone>>(
        milestoneToastProvider, (_, next) => _showMilestones(next));

    final l10n = AppLocalizations.of(context)!;
    final isCompact = DesignSystem.isMobile(context);
    final destinations = <({IconData icon, IconData selected, String label})>[
      (icon: Icons.bar_chart_outlined, selected: Icons.bar_chart_rounded, label: l10n.statsTitle),
      (icon: Icons.grid_view_outlined, selected: Icons.grid_view_rounded, label: l10n.games),
      (icon: Icons.settings_outlined, selected: Icons.settings_rounded, label: l10n.settings),
    ];

    final body = IndexedStack(
      index: _selectedIndex,
      children: [
        for (var i = 0; i < destinations.length; i++)
          _visited.contains(i)
              ? TickerMode(enabled: i == _selectedIndex, child: _screen(i))
              : const SizedBox.shrink(),
      ],
    );

    if (isCompact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(children: [
        SafeArea(
          child: NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            groupAlignment: 0,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outline),
        Expanded(child: body),
      ]),
    );
  }
}
