import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/akari/akari_campaign_data.dart';
import 'package:puzzle/ui/features/games/akari/akari_engine.dart';
import 'package:puzzle/ui/features/games/akari/akari_provider.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';

// Independent rule checker: legal bulbs cannot see each other; every white
// square must be illuminated; numbered black squares require exact counts.
// Stop searching after two distinct solutions (uniqueness certification).
int countAkariSolutions(List<List<int>> board) {
  final n = board.length;
  final whites = <(int, int)>[
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++)
        if (board[r][c] == -2) (r, c),
  ];
  final index = <(int, int), int>{
    for (var i = 0; i < whites.length; i++) whites[i]: i,
  };
  final lines = <int>[];
  for (final cell in whites) {
    var mask = 1 << index[cell]!;
    for (final (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      var r = cell.$1 + dr;
      var c = cell.$2 + dc;
      while (r >= 0 && c >= 0 && r < n && c < n && board[r][c] == -2) {
        mask |= 1 << index[(r, c)]!;
        r += dr;
        c += dc;
      }
    }
    lines.add(mask);
  }

  final clues = <(int, int)>[];
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (board[r][c] < 0) continue;
      var neighborMask = 0;
      for (final (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final cellIndex = index[(r + dr, c + dc)];
        if (cellIndex != null) neighborMask |= 1 << cellIndex;
      }
      clues.add((board[r][c], neighborMask));
    }
  }

  int popcount(int x) {
    var count = 0;
    while (x != 0) {
      x &= x - 1;
      count++;
    }
    return count;
  }

  final full = (1 << whites.length) - 1;
  final seen = <int>{};
  void search(int lit, int bulbs) {
    if (seen.length >= 2) return;
    if (lit == full) {
      if (clues.every((clue) => popcount(bulbs & clue.$2) == clue.$1)) {
        seen.add(bulbs);
      }
      return;
    }
    List<int>? options;
    for (var cell = 0; cell < whites.length; cell++) {
      if ((lit & (1 << cell)) != 0) continue;
      final candidate = <int>[
        for (var i = 0; i < whites.length; i++)
          if ((lines[i] & (1 << cell)) != 0 && (lit & (1 << i)) == 0) i,
      ];
      if (candidate.isEmpty) return;
      if (options == null || candidate.length < options.length) {
        options = candidate;
        if (options.length == 1) break;
      }
    }
    for (final i in options!) {
      final nextBulbs = bulbs | (1 << i);
      final nextLit = lit | lines[i];
      if (clues.any((clue) {
        final need = clue.$1;
        final placed = popcount(nextBulbs & clue.$2);
        final possible = popcount(clue.$2 & ~nextLit);
        return placed > need || placed + possible < need;
      })) {
        continue;
      }
      search(nextLit, nextBulbs);
      if (seen.length >= 2) return;
    }
  }

  search(0, 0);
  return seen.length;
}

void main() {
  test('Akari campaign contains 20 distinct, uniquely solvable puzzles', () {
    expect(AkariCampaignData.levelCount, 20);
    final fingerprints = <String>{};
    for (var level = 1; level <= 20; level++) {
      final entry = AkariCampaignData.level(level);
      final grid = AkariCampaignData.board(level);
      final size = entry.size;
      expect(size, inInclusiveRange(5, 7));
      expect(grid.length, size);
      expect(grid.every((row) => row.length == size), isTrue);
      expect(grid.expand((row) => row).every((v) => v >= -2 && v <= 4), isTrue);
      expect(fingerprints.add(grid.map((row) => row.join(',')).join('|')), isTrue);
      final bulbs = List.generate(size, (_) => List.filled(size, false));
      for (final position in entry.solution) {
        final row = position ~/ size;
        final col = position % size;
        expect(grid[row][col], -2);
        bulbs[row][col] = true;
      }
      final lit = AkariEngine.calculateLit(grid, bulbs);
      expect(AkariEngine.checkVictory(grid, bulbs, lit), isTrue,
          reason: 'Authored solution for level $level must win');
      expect(countAkariSolutions(grid), 1,
          reason: 'Level $level must have exactly one solution');
    }
    expect(() => AkariCampaignData.level(0), throwsRangeError);
    expect(() => AkariCampaignData.level(21), throwsRangeError);
  });

  test('Akari active bulbs and selected level survive a fresh provider', () async {
    final directory = await Directory.systemTemp.createTemp('akari-save-');
    Hive.init(directory.path);
    await Hive.openBox('app_meta');
    final initial = ProviderContainer();
    final keepAlive = initial.listen(akariNotifierProvider, (_, __) {});
    try {
      final notifier = initial.read(akariNotifierProvider.notifier);
      notifier.loadLevel(10);
      final level = AkariCampaignData.level(10);
      final first = level.solution.first;
      notifier.toggleBulb(first ~/ level.size, first % level.size);
      await notifier.flushProgress();
      expect(CampaignProgress.selectedLevel('akari', count: 20), 10);
      expect(CampaignProgress.loadActive('akari', 10, maxLength: 36), [first]);
      keepAlive.close();
      initial.dispose();
      final restored = ProviderContainer();
      final restoredKeepAlive = restored.listen(akariNotifierProvider, (_, __) {});
      try {
        final resumed = restored.read(akariNotifierProvider.notifier);
        resumed.initGame();
        expect(restored.read(akariNotifierProvider).levelNumber, 10);
        expect(restored.read(akariNotifierProvider).bulbs[first ~/ level.size]
            [first % level.size], isTrue);
        resumed.restartLevel();
        await resumed.flushProgress();
        expect(CampaignProgress.loadActive('akari', 10, maxLength: 36), isNull);
      } finally {
        restoredKeepAlive.close();
        restored.dispose();
      }
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('Akari completion is saved without requiring an online connection', () async {
    final directory = await Directory.systemTemp.createTemp('akari-win-');
    Hive.init(directory.path);
    await Hive.openBox('app_meta');
    final container = ProviderContainer();
    final keepAlive = container.listen(akariNotifierProvider, (_, __) {});
    try {
      final notifier = container.read(akariNotifierProvider.notifier);
      notifier.loadLevel(1);
      final level = AkariCampaignData.level(1);
      for (final index in level.solution) {
        notifier.toggleBulb(index ~/ level.size, index % level.size);
      }
      expect(container.read(akariNotifierProvider).isVictory, isTrue);
      await notifier.flushProgress();
      expect(CampaignProgress.load('akari'), contains(1));
      expect(CampaignProgress.loadActive('akari', 1, maxLength: 25), isNull);
    } finally {
      keepAlive.close();
      container.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
