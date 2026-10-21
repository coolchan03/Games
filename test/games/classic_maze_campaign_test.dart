import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/classic_maze/classic_maze_engine.dart';
import 'package:puzzle/ui/features/games/classic_maze/classic_maze_provider.dart';
import 'package:puzzle/ui/features/games/classic_maze/classic_maze_screen.dart';

List<int> pathToExit(ClassicMazeLevel level) {
  final size = level.size;
  final start = level.startR * size + level.startC;
  final finish = level.exitR * size + level.exitC;
  final seen = <int>{start};
  final previous = <int, int>{};
  final queue = Queue<int>()..add(start);
  while (queue.isNotEmpty && !seen.contains(finish)) {
    final cell = queue.removeFirst();
    final r = cell ~/ size;
    final c = cell % size;
    for (final dir in const [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      final nr = r + dir[0];
      final nc = c + dir[1];
      if (nr < 0 || nc < 0 || nr >= size || nc >= size ||
          level.grid[nr][nc] != 0) continue;
      final neighbor = nr * size + nc;
      if (!seen.add(neighbor)) continue;
      previous[neighbor] = cell;
      queue.add(neighbor);
    }
  }
  if (!seen.contains(finish)) return const [];
  final path = <int>[finish];
  for (var cell = finish; cell != start; cell = previous[cell]!) {
    path.add(previous[cell]!);
  }
  return path.reversed.toList();
}

void main() {
  test('Classic Maze has 20 unique seeded, fully reachable mazes', () {
    expect(ClassicMazeEngine.campaignLevelCount, 20);
    final fingerprints = <String>{};
    for (var level = 1; level <= 20; level++) {
      final maze = ClassicMazeEngine.campaignLevel(level);
      final size = ClassicMazeEngine.sizeForLevel(level);
      expect(maze.size, size);
      expect(size, 11 + ((level - 1) ~/ 2) * 2);
      expect(maze.grid.length, size);
      expect(maze.grid.every((row) => row.length == size), true);
      expect(maze.grid[maze.startR][maze.startC], 0);
      expect(maze.grid[maze.exitR][maze.exitC], 0);
      final path = pathToExit(maze);
      expect(path.length, greaterThan(4),
          reason: 'Maze $level has no traversable route to the exit');
      expect(fingerprints.add(maze.grid.toString()), true,
          reason: 'Maze $level is identical to a previous level');
    }
    for (final level in [1, 8, 20]) {
      final first = ClassicMazeEngine.campaignLevel(level);
      final second = ClassicMazeEngine.campaignLevel(level);
      expect(first.grid, second.grid,
          reason: 'Maze level $level changed on reload');
    }
    expect(() => ClassicMazeEngine.sizeForLevel(0), throwsRangeError);
    expect(() => ClassicMazeEngine.campaignLevel(21), throwsRangeError);
  });

  test('Classic Maze resumes the same player position and protects corrupt data',
      () async {
    final directory = await Directory.systemTemp.createTemp('maze-save-');
    final initialContainer = ProviderContainer();
    try {
      Hive.init(directory.path);
      await Hive.openBox('app_meta');
      final notifier = initialContainer.read(classicMazeNotifierProvider.notifier);
      notifier.loadLevel(7);
      final maze = initialContainer.read(classicMazeNotifierProvider);
      expect(maze.levelNumber, 7);
      final downOpen = maze.grid[maze.playerRow + 1][maze.playerCol] == 0;
      final stepR = downOpen ? 1 : 0;
      final stepC = downOpen ? 0 : 1;
      expect(notifier.movePlayer(stepR, stepC), true);
      final moved = initialContainer.read(classicMazeNotifierProvider);
      expect(moved.moves, 1);
      await Hive.box('app_meta').flush();
      expect(CampaignProgress.selectedLevel('classic_maze', count: 20), 7);
      expect(CampaignProgress.loadActive('classic_maze', 7,
          maxLength: 6001), hasLength(3));
      initialContainer.dispose();
      final restoredContainer = ProviderContainer();
      try {
        final restoreNotifier = restoredContainer.read(
            classicMazeNotifierProvider.notifier);
        restoreNotifier.initGame();
        final restored = restoredContainer.read(classicMazeNotifierProvider);
        expect(restored.moves, moved.moves);
        expect(restored.playerRow, moved.playerRow);
        expect(restored.playerCol, moved.playerCol);
        expect(restored.visitedPath, moved.visitedPath);

        await CampaignProgress.saveActive('classic_maze', 7, [99, -999]);
        restoreNotifier.loadLevel(7);
        final clean = restoredContainer.read(classicMazeNotifierProvider);
        expect(clean.moves, 0);
        expect(clean.playerRow, 1);
        expect(clean.playerCol, 1);
      } finally {
        restoredContainer.dispose();
      }
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets('Maze level controls work on a phone-sized screen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClassicMazeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('classic_maze_level_selector')),
        findsOneWidget);
    expect(find.textContaining('Level 1 - 11x11'), findsOneWidget);
    await tester.tap(find.byTooltip('Next maze level'));
    await tester.pump();
    expect(find.textContaining('Level 2 - 11x11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
