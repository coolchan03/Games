import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_engine.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_provider.dart';
import 'package:puzzle/ui/features/games/minesweeper/minesweeper_screen.dart';

Set<int> minePositions(List<List<MinesweeperCell>> board) {
  final cols = board.first.length;
  return {
    for (var r = 0; r < board.length; r++)
      for (var c = 0; c < cols; c++)
        if (board[r][c].isMine) r * cols + c,
  };
}

void main() {
  test('twenty seeded levels are distinct and increase in challenge', () {
    expect(MinesweeperEngine.campaignLevelCount, 20);
    final fingerprints = <String>{};
    for (var level = 1; level <= MinesweeperEngine.campaignLevelCount;
        level++) {
      final mines = MinesweeperEngine.minesForLevel(level);
      expect(mines, 8 + level);
      final engine = MinesweeperEngine(
        rows: 10, cols: 8,
        mineCount: mines,
        seed: MinesweeperEngine.seedForLevel(level),
      );
      final before = engine.generateBoard();
      final board = engine.generateBoard(startRow: 5, startCol: 4);
      final positions = minePositions(board);
      expect(minePositions(before).length, mines);
      expect(positions.length, mines);
      for (var r = 4; r <= 6; r++) {
        for (var c = 3; c <= 5; c++) {
          expect(board[r][c].isMine, false,
              reason: 'Level $level contains a mine beside first click');
        }
      }
      for (var r = 0; r < 10; r++) {
        for (var c = 0; c < 8; c++) {
          final neighbors = <int>[
            for (var dr = -1; dr <= 1; dr++)
              for (var dc = -1; dc <= 1; dc++)
                if (r + dr >= 0 && r + dr < 10 &&
                    c + dc >= 0 && c + dc < 8 &&
                    board[r + dr][c + dc].isMine)
                  1,
          ].length;
          expect(board[r][c].neighborMines, neighbors);
        }
      }
      final fingerprint = positions.toList()..sort();
      expect(fingerprints.add(fingerprint.join(',')), true,
          reason: 'Level $level duplicates another mine field');
      final again = MinesweeperEngine(
        rows: 10, cols: 8,
        mineCount: mines,
        seed: MinesweeperEngine.seedForLevel(level),
      ).generateBoard(startRow: 5, startCol: 4);
      expect(minePositions(again), positions);
      expect(engine.checkWin(board), isFalse);

      // The victory condition is reachable by revealing all non-mine cells.
      final cleared = [
        for (final row in board)
          [for (final cell in row)
            cell.isMine ? cell : cell.copyWith(state: CellState.revealed)],
      ];
      expect(engine.checkWin(cleared), true);
    }
    expect(fingerprints.length, 20);
    expect(() => MinesweeperEngine.minesForLevel(21), throwsRangeError);
  });

  test('safe first-click validation fails quickly for impossible boards', () {
    expect(() => MinesweeperEngine(rows: 2, cols: 2, mineCount: 4),
        throwsArgumentError);
    final engine = MinesweeperEngine(rows: 2, cols: 2, mineCount: 2);
    expect(() => engine.generateBoard(startRow: 0), throwsArgumentError);
    expect(() => engine.generateBoard(startRow: -1, startCol: 0),
        throwsRangeError);
    expect(() => engine.generateBoard(startRow: 0, startCol: 0),
        throwsArgumentError, reason: 'Cannot protect 3x3 when no spaces remain');
  });

  test('flagging before first reveal survives deterministic layout change',
      () async {
    final temp = await Directory.systemTemp.createTemp('minesweeper-campaign-');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    try {
      Hive.init(temp.path);
      await Hive.openBox('app_meta');
      final notifier = container.read(minesweeperNotifierProvider.notifier);
      expect(container.read(minesweeperNotifierProvider).levelNumber, 1);
      notifier.loadLevel(14);
      expect(container.read(minesweeperNotifierProvider).totalMines, 22);
      notifier.toggleFlag(0, 0);
      expect(container.read(minesweeperNotifierProvider).minesRemaining, 21);
      notifier.revealCell(5, 4);
      final state = container.read(minesweeperNotifierProvider);
      expect(state.firstMove, false);
      expect(state.board[0][0].state, CellState.flagged);
      expect(state.board[5][4].state, CellState.revealed);
      expect(state.minesRemaining, 21);
      notifier.reset();
      expect(container.read(minesweeperNotifierProvider).levelNumber, 14);
      expect(container.read(minesweeperNotifierProvider).firstMove, true);
      expect(CampaignProgress.selectedLevel('minesweeper', count: 20), 14);
    } finally {
      await Hive.close();
      await temp.delete(recursive: true);
    }
  });

  testWidgets('phone-sized screen navigates twenty levels', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MinesweeperScreen(),
      ),
    ));
    expect(find.byKey(const ValueKey('minesweeper_level_selector')),
        findsOneWidget);
    expect(find.textContaining('Level 1 of 20'), findsOneWidget);
    await tester.tap(find.byTooltip('Next Minesweeper level'));
    await tester.pump();
    expect(find.textContaining('Level 2 of 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
