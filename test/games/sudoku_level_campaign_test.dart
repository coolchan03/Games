import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_engine.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_provider.dart';
import 'package:puzzle/ui/features/games/sudoku/sudoku_screen.dart';

/// Layout tests exercise the real screen and navigation without invoking the
/// expensive isolate-backed generator. Engine uniqueness and provider
/// persistence are covered by independent tests above.
SudokuState _layoutFixture(int level) {
  final solved = List.generate(9, (r) =>
      List.generate(9, (c) => ((r * 3 + r ~/ 3 + c) % 9) + 1));
  final initial = [for (final row in solved) List<int>.from(row)];
  initial[0][0] = 0;
  return SudokuState(
    initialBoard: initial.map((r) => r.lock).toIList(),
    currentBoard: initial.map((r) => r.lock).toIList(),
    solvedBoard: solved.map((r) => r.lock).toIList(),
    levelNumber: level,
  );
}

class _LayoutSudokuNotifier extends SudokuNotifier {
  @override
  Future<SudokuState> build() async => _layoutFixture(1);

  @override
  Future<void> loadLevel(int level) async {
    state = AsyncValue.data(_layoutFixture(level));
  }
}

void main() {
  test('Sudoku campaign creates 20 distinct unique-solution levels', () {
    expect(SudokuEngine.campaignLevelCount, 20);
    final fingerprints = <String>{};
    for (var level = 1; level <= 20; level++) {
      final puzzle = SudokuEngine.generateCampaignPuzzle(level);
      expect(puzzle.level, level);
      expect(puzzle.clues, greaterThanOrEqualTo(
          SudokuEngine.cluesForLevel(level)));
      expect(puzzle.clues, lessThan(81));
      expect(SudokuEngine.countSolutions(puzzle.initial), 1,
          reason: 'Sudoku level $level lacks a unique solution');
      expect(SudokuEngine().isCorrect(puzzle.solution, puzzle.solution), true);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle.initial[r][c] != 0) {
            expect(puzzle.initial[r][c], puzzle.solution[r][c]);
          }
        }
      }
      expect(fingerprints.add(puzzle.initial.toString()), true,
          reason: 'Sudoku level $level duplicates an earlier puzzle');
    }
    expect(SudokuEngine.cluesForLevel(1), 44);
    expect(SudokuEngine.cluesForLevel(20), 28);
    final original = SudokuEngine.generateCampaignPuzzle(1);
    final repeated = SudokuEngine.generateCampaignPuzzle(1);
    expect(repeated.initial, original.initial);
    expect(repeated.solution, original.solution);
    expect(() => SudokuEngine.cluesForLevel(21), throwsRangeError);
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('Sudoku uniqueness checker rejects invalid and ambiguous boards', () {
    expect(SudokuEngine.countSolutions(
      List.generate(9, (_) => List.filled(9, 0)), limit: 2), 2);
    final duplicate = List.generate(9, (_) => List.filled(9, 0));
    duplicate[0][0] = 1;
    duplicate[0][3] = 1;
    expect(SudokuEngine.countSolutions(duplicate), 0);
  });

  test('Sudoku active entries and selected level survive app restart',
      () async {
    final directory = await Directory.systemTemp.createTemp('sudoku-save-');
    final firstContainer = ProviderContainer();
    try {
      Hive.init(directory.path);
      await Hive.openBox('app_meta');
      final firstKeepAlive = firstContainer.listen(
          sudokuNotifierProvider, (previous, next) {});
      final first = await firstContainer.read(sudokuNotifierProvider.future);
      final original = first.initialBoard;
      var emptyR = -1;
      var emptyC = -1;
      for (var r = 0; r < 9 && emptyR < 0; r++) {
        for (var c = 0; c < 9; c++) {
          if (original[r][c] == 0) {
            emptyR = r;
            emptyC = c;
            break;
          }
        }
      }
      expect(emptyR, greaterThanOrEqualTo(0));
      final notifier = firstContainer.read(sudokuNotifierProvider.notifier);
      notifier.selectCell(emptyR, emptyC);
      final value = first.solvedBoard[emptyR][emptyC];
      await notifier.setNumber(value);
      await Hive.box('app_meta').flush();
      expect(CampaignProgress.loadActive('sudoku', 1, maxLength: 81),
          hasLength(81));
      final firstValue = firstContainer.read(sudokuNotifierProvider).value!;
      expect(firstValue.currentBoard[emptyR][emptyC], value);

      firstKeepAlive.close();
      firstContainer.dispose();
      final second = ProviderContainer();
      final secondKeepAlive = second.listen(
          sudokuNotifierProvider, (previous, next) {});
      try {
        final restored = await second.read(sudokuNotifierProvider.future);
        expect(restored.levelNumber, 1);
        expect(restored.currentBoard[emptyR][emptyC], value);
        expect(restored.initialBoard[emptyR][emptyC], 0);
      } finally {
        secondKeepAlive.close();
        second.dispose();
      }

      final completed = {1, 3, 20};
      await CampaignProgress.save('sudoku', completed);
      await CampaignProgress.saveSelected('sudoku', 14);
      await Hive.box('app_meta').close();
      await Hive.openBox('app_meta');
      expect(CampaignProgress.load('sudoku'), completed);
      expect(CampaignProgress.selectedLevel('sudoku', count: 20), 14);
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('phone layout exposes Sudoku chapter navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sudokuNotifierProvider.overrideWith(_LayoutSudokuNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SudokuScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('sudoku_level_selector')),
        findsOneWidget);
    expect(find.textContaining('Level 1 of 20'), findsOneWidget);
    await tester.tap(find.byTooltip('Next Sudoku level'));
    await tester.pump();
    expect(find.textContaining('Level 2 of 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
