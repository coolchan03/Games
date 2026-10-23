import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/kakuro/kakuro_campaign_data.dart';
import 'package:puzzle/ui/features/games/kakuro/kakuro_engine.dart';
import 'package:puzzle/ui/features/games/kakuro/kakuro_provider.dart';

void main() {
  test('Kakuro campaign contains 20 distinct, uniquely solvable boards', () {
    expect(KakuroCampaignData.levelCount, 20);
    final fingerprints = <String>{};
    var previousLargest = 0;
    for (var number = 1; number <= KakuroCampaignData.levelCount; number++) {
      final level = KakuroEngine.campaignLevel(number);
      final seed = KakuroCampaignData.seed(number);
      expect(level.size, inInclusiveRange(4, 7));
      expect(level.grid.length, level.size);
      expect(level.grid.every((row) => row.length == level.size), isTrue);
      final fingerprint = seed.cells.map((row) => row.join(',')).join('|') +
          ':${seed.starters.join(',')}';
      expect(fingerprints.add(fingerprint), isTrue,
          reason: 'Level $number repeats a previous puzzle');
      final values = KakuroEngine.startingValues(level);
      final blanks = values.values.where((digit) => digit == null).length;
      expect(blanks, greaterThanOrEqualTo(3),
          reason: 'Level $number has too little meaningful work');
      expect(values.length, greaterThanOrEqualTo(previousLargest),
          reason: 'White-cell difficulty must not shrink');
      previousLargest = values.length;
      final solution = <Point<int>, int?>{
        for (final row in level.grid)
          for (final cell in row)
            if (cell.isWhite) Point(cell.c, cell.r): cell.solution!,
      };
      expect(KakuroEngine.checkSolved(level, solution), isTrue,
          reason: 'Level $number must accept the published solution');
      final runs = KakuroEngine.clueRuns(level);
      expect(runs, isNotEmpty);
      expect(runs.every((run) => run.positions.length >= 2), isTrue);
      expect(KakuroEngine.countSolutions(level), 1,
          reason: 'Level $number must have exactly one solution');
      final wrong = Map<Point<int>, int?>.of(solution);
      final editable = level.grid.expand((r) => r)
          .firstWhere((cell) => cell.isWhite && !cell.isGiven);
      wrong[Point(editable.c, editable.r)] = null;
      expect(KakuroEngine.checkSolved(level, wrong), isFalse);
    }
    expect(() => KakuroCampaignData.seed(0), throwsRangeError);
    expect(() => KakuroCampaignData.seed(21), throwsRangeError);
  });

  test('Kakuro selected level and partial digits survive provider recreation',
      () async {
    final directory = await Directory.systemTemp.createTemp('kakuro-save-');
    Hive.init(directory.path);
    await Hive.openBox('app_meta');
    final first = ProviderContainer();
    final subscription = first.listen(kakuroNotifierProvider, (_, __) {});
    try {
      final notifier = first.read(kakuroNotifierProvider.notifier);
      notifier.loadLevel(10);
      final level = first.read(kakuroNotifierProvider).level;
      final entry = level.grid.expand((row) => row)
          .firstWhere((cell) => cell.isWhite && !cell.isGiven);
      notifier.selectCell(entry.r, entry.c);
      notifier.setCellValue(entry.solution!);
      await notifier.flushProgress();
      expect(CampaignProgress.selectedLevel('kakuro', count: 20), 10);
      expect(CampaignProgress.loadActive('kakuro', 10,
          maxLength: level.size * level.size * 2), isNotEmpty);
      subscription.close();
      first.dispose();

      final second = ProviderContainer();
      final secondSubscription =
          second.listen(kakuroNotifierProvider, (_, __) {});
      try {
        final resumed = second.read(kakuroNotifierProvider.notifier);
        final state = second.read(kakuroNotifierProvider);
        expect(state.level.levelNumber, 10);
        expect(state.currentValues[Point(entry.c, entry.r)], entry.solution);
        resumed.restartLevel();
        await resumed.flushProgress();
        expect(second.read(kakuroNotifierProvider)
            .currentValues[Point(entry.c, entry.r)], isNull);
        expect(CampaignProgress.loadActive('kakuro', 10,
            maxLength: level.size * level.size * 2), isNull);
      } finally {
        secondSubscription.close();
        second.dispose();
      }
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('Kakuro completion is recorded offline and starters cannot be changed',
      () async {
    final directory = await Directory.systemTemp.createTemp('kakuro-win-');
    Hive.init(directory.path);
    await Hive.openBox('app_meta');
    final container = ProviderContainer();
    final subscription = container.listen(kakuroNotifierProvider, (_, __) {});
    try {
      final notifier = container.read(kakuroNotifierProvider.notifier);
      notifier.loadLevel(1);
      final level = container.read(kakuroNotifierProvider).level;
      final given = level.grid.expand((row) => row)
          .firstWhere((cell) => cell.isWhite && cell.isGiven);
      notifier.selectCell(given.r, given.c);
      notifier.setCellValue(9);
      expect(container.read(kakuroNotifierProvider).currentValues[
          Point(given.c, given.r)], given.solution);
      for (final row in level.grid) {
        for (final cell in row) {
          if (cell.isWhite && !cell.isGiven) {
            notifier.selectCell(cell.r, cell.c);
            notifier.setCellValue(cell.solution!);
          }
        }
      }
      expect(container.read(kakuroNotifierProvider).isSolved, isTrue);
      await notifier.flushProgress();
      expect(CampaignProgress.load('kakuro'), contains(1));
      expect(CampaignProgress.loadActive('kakuro', 1,
          maxLength: level.size * level.size * 2), isNull);
      notifier.newGame();
      expect(container.read(kakuroNotifierProvider).level.levelNumber, 2);
    } finally {
      subscription.close();
      container.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
