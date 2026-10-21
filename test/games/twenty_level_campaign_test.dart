import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_engine.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_screen.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_engine.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_provider.dart';

void main() {
  test('detective campaign has twenty distinct, solvable mysteries', () {
    expect(DetectiveCasebook.cases.length, 12);
    expect(DetectiveCasebook.campaignCount, 20);
    final cases = [
      for (var chapter = 0; chapter < DetectiveCasebook.campaignCount; chapter++)
        DetectiveCasebook.campaignCase(chapter),
    ];
    expect(cases.map((c) => c.id).toSet().length, 20);
    for (var i = 0; i < cases.length; i++) {
      expect(cases[i].countSolutions(), 1, reason: 'Case ${i + 1} ambiguous');
      expect(DetectiveCasebook.campaignTitle(i), isNotEmpty);
      if (i >= 16) expect(cases[i].difficulty, CaseDifficulty.hard);
    }
    expect(identical(
      DetectiveCasebook.campaignCase(19),
      DetectiveCasebook.campaignCase(19),
    ), isTrue, reason: 'Reopening the chapter preserves its puzzle');
    expect(() => DetectiveCasebook.campaignCase(20), throwsRangeError);
  });

  test('Nonogram campaign generates twenty reproducible unique-solution levels', () {
    expect(NonogramEngine.campaignLevelCount, 20);
    final fingerprints = <String>{};
    for (var level = 1; level <= 20; level++) {
      final size = NonogramEngine.sizeForLevel(level);
      expect(size, 5 + (level - 1) ~/ 4);
      final puzzle = NonogramEngine.generateCampaignPuzzle(level);
      expect(puzzle.rowClues.length, size);
      expect(puzzle.colClues.length, size);
      expect(NonogramEngine.countSolutions(puzzle, size), 1,
          reason: 'Nonogram $level has multiple solutions');
      final fingerprint = '${puzzle.rowClues};${puzzle.colClues}';
      expect(fingerprints.add(fingerprint), isTrue,
          reason: 'Level $level repeats an earlier puzzle');
    }
    final first = NonogramEngine.generateCampaignPuzzle(1);
    final repeated = NonogramEngine.generateCampaignPuzzle(1);
    expect(first.rowClues.toString(), repeated.rowClues.toString());
    expect(first.colClues.toString(), repeated.colClues.toString());
    expect(() => NonogramEngine.sizeForLevel(21), throwsRangeError);
  });

  test('Nonogram uniqueness solver rejects ambiguous clue combinations', () {
    final ambiguous = NonogramPuzzle(
      rowClues: [[1], [1]], colClues: [[1], [1]],
    );
    final unique = NonogramPuzzle(
      rowClues: [[2], [0]], colClues: [[1], [1]],
    );
    expect(NonogramEngine.countSolutions(ambiguous, 2), 2);
    expect(NonogramEngine.countSolutions(unique, 2), 1);
  });

  test('Nonogram state keeps its level across cell updates', () {
    final state = NonogramState(
      grid: [[0]],
      rowClues: [[1]],
      colClues: [[1]],
      size: 1,
      levelNumber: 17,
    );
    expect(state.copyWith(grid: [[1]]).levelNumber, 17);
  });

  test('campaign completion and selected level survive reopening Hive', () async {
    final temporary = await Directory.systemTemp.createTemp('games-20-levels-');
    try {
      Hive.init(temporary.path);
      await Hive.openBox('app_meta');
      await CampaignProgress.save('detective_casebook', {1, 12, 20});
      await CampaignProgress.saveSelected('detective_casebook', 16);
      expect(CampaignProgress.load('detective_casebook'), {1, 12, 20});
      expect(CampaignProgress.selectedLevel(
        'detective_casebook', count: 20), 16);
      await Hive.box('app_meta').close();
      await Hive.openBox('app_meta');
      expect(CampaignProgress.load('detective_casebook'), {1, 12, 20});
      expect(CampaignProgress.selectedLevel(
        'detective_casebook', count: 20), 16);
      expect(CampaignProgress.selectedLevel(
        'nonogram', count: 20), 1);
    } finally {
      await Hive.close();
      await temporary.delete(recursive: true);
    }
  });

  testWidgets('Detective case selector advances between campaign chapters',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: DetectiveCasebookScreen()),
    );
    expect(find.text('Campaign case 1 of 20'), findsOneWidget);
    await tester.tap(find.byTooltip('Next case'));
    await tester.pump();
    expect(find.text('Campaign case 2 of 20'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous case'));
    await tester.pump();
    expect(find.text('Campaign case 1 of 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
