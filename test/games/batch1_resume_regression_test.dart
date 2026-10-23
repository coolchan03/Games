import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/code_breaker/code_breaker_engine.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_screen.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/layered_board.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_engine.dart';

void main() {
  test('Code Breaker restores its secret and every scored guess', () {
    final game = CodeBreakerGame(
      CodeBreakerMode.classic, secret: [0, 1, 1, 2],
    );
    expect(game.submit([1, 0, 1, 3]), true);
    expect(game.feedback.last, (1, 2));
    final snapshot = game.snapshot();
    final restored = CodeBreakerGame.restore(CodeBreakerMode.classic, snapshot);
    expect(restored, isNotNull);
    expect(restored!.secret, game.secret);
    expect(restored.guesses, game.guesses);
    expect(restored.feedback, game.feedback);
    expect(restored.over, false);

    expect(CodeBreakerGame.restore(
      CodeBreakerMode.classic, [8, ...snapshot.skip(1)],
    ), isNull, reason: 'invalid colours cannot be restored');
    expect(CodeBreakerGame.restore(
      CodeBreakerMode.classic, [...snapshot, 0],
    ), isNull, reason: 'invalid payload lengths cannot be restored');
  });

  test('Sokoban restores moved crates but rejects walls and bad counters', () {
    final walls = <int>{
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++)
          if (x == 0 || y == 0 || x == 4 || y == 4) y * 5 + x,
    };
    final level = SokobanLevel(5, 5, walls, {7}, {12}, 17, 1);
    final game = SokobanGame(level);
    expect(game.step(0), true);
    expect(game.solved, true);

    final snapshot = game.snapshot();
    final restored = SokobanGame(level);
    expect(restored.restore(snapshot), true);
    expect(restored.player, game.player);
    expect(restored.boxes, game.boxes);
    expect(restored.moves, 1);
    expect(restored.pushes, 1);
    expect(restored.solved, true);
    expect(restored.canUndo, false, reason: 'saved board has no stale undo');

    expect(SokobanGame(level).restore([0, 1, 1, 7]), false);
    expect(SokobanGame(level).restore([12, 0, 3, 7]), false);
  });

  test('Mahjong restores the actual deal and removed tiles', () {
    final layout = Layout.all().last;
    final board = LayeredBoard(layout, random: Random(42));
    final first = board.solution.first;
    expect(board.remove(first.$1, first.$2), true);
    final snapshot = board.snapshot();
    final restored = LayeredBoard(layout, random: Random(7));
    expect(restored.restore(snapshot), true);
    expect(restored.remaining, board.remaining);
    expect(restored.snapshot(), snapshot);
    expect(restored.history, isEmpty);
    expect(restored.moves, isNotEmpty);
    expect(restored.restore([0, -2]), false);
    expect(restored.restore([0, ...List.filled(layout.slots.length, -2)]), false);
  });

  test('All Batch 1 offline state keys persist through a Hive restart', () async {
    final folder = await Directory.systemTemp.createTemp('games-batch1-resume-');
    try {
      Hive.init(folder.path);
      await Hive.openBox('app_meta');
      await CampaignProgress.saveActive('code_breaker', 2, [0, 1, 1, 2, 0, -1, -1, -1, -1, 0]);
      await CampaignProgress.saveActive('sokoban_1', 3, [12, 1, 1, 7]);
      await CampaignProgress.saveActive('mahjong_solitaire', 9, [0, -1, -1]);
      await CampaignProgress.saveActive('detective_casebook', 1, [0, -1, 0, 0]);
      await CampaignProgress.saveSelected('mahjong_solitaire', 9);
      await Hive.box('app_meta').close();
      await Hive.openBox('app_meta');
      expect(CampaignProgress.loadActive('sokoban_1', 3, maxLength: 4), [12, 1, 1, 7]);
      expect(CampaignProgress.loadActive('mahjong_solitaire', 9, maxLength: 4), [0, -1, -1]);
      expect(CampaignProgress.loadActive('detective_casebook', 1, maxLength: 4), [0, -1, 0, 0]);
      expect(CampaignProgress.selectedLevel('mahjong_solitaire', count: 9), 9);
    } finally {
      await Hive.close();
      await folder.delete(recursive: true);
    }
  });

  testWidgets('Detective clue checkmarks survive closing and reopening a case',
      (tester) async {
    final folder = await Directory.systemTemp.createTemp('games-casebook-resume-');
    try {
      Hive.init(folder.path);
      await Hive.openBox('app_meta');
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: DetectiveCasebookScreen()));
      // Bounded drags avoid waiting indefinitely for lazy ListView children.
      Future<void> revealFirstClue() async {
        final finder = find.byType(CheckboxListTile);
        for (var attempt = 0;
            attempt < 8 && finder.evaluate().isEmpty;
            attempt++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }
        expect(finder, findsWidgets);
        await tester.ensureVisible(finder.first);
        await tester.pump();
      }
      await revealFirstClue();
      final clue = find.byType(CheckboxListTile).first;
      await tester.tap(clue);
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(clue).value, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: DetectiveCasebookScreen()));
      await revealFirstClue();
      expect(tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile).first).value, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    } finally {
      await Hive.close();
      await folder.delete(recursive: true);
    }
  });
}
