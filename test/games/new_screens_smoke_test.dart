import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';

/// Games added on top of the original Puzzle catalogue. Each screen is
/// pumped for a while so computer opponents get to move, then disposed.
const addedGames = [
  'chess', 'hearts', 'spades', 'oh_hell', 'yacht_dice', 'code_breaker',
  'texas_holdem', 'five_card_draw', 'video_poker', 'klondike', 'freecell', 'spider',
  'golf_solitaire', 'pyramid', 'backgammon', 'ludo', 'nine_mens_morris',
  'gomoku', 'dots_and_boxes', 'battleship', 'snakes_and_ladders',
  'peg_solitaire', 'shut_the_box', 'tower_of_hanoi', 'memory_pairs',
  'mahjong_solitaire', 'detective_casebook', 'crazy_eights', 'go_fish',
  'gin_rummy', 'blackjack', 'inertia', 'same_game', 'black_box', 'twiddle',
  'sixteen', 'signpost', 'hex', 'go_game', 'liars_dice', 'dominoes',
  'bagh_chal', 'alquerque', 'neutron', 'chinese_checkers', 'poker_squares',
  'aces_up', 'forty_thieves', 'sokoban', 'oware', 'nim', 'war',
  'cribbage', 'air_hockey', 'goose_game', 'kings_corner', 'dice_421',
];

void main() {
  late Directory tempHive;
  setUpAll(() async {
    tempHive = await Directory.systemTemp.createTemp('games-smoke-hive-');
    Hive.init(tempHive.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await tempHive.delete(recursive: true);
  });
  for (final id in addedGames) {
    testWidgets('$id screen renders and runs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0; // 360 dp wide phone
      addTearDown(tester.view.reset);
      final GameMetadata meta = allGamesMetadata.firstWhere((g) => g.id == id);
      await tester.pumpWidget(MaterialApp(home: Builder(builder: meta.builder)));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
      // Open the rules dialog and start a new game (shared GameScaffold).
      if (find.byTooltip('Rules').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Rules'));
        await tester.pump(const Duration(seconds: 1));
        final closeRules = find.text('Got it').evaluate().isNotEmpty
            ? find.text('Got it') : find.text('Close');
        expect(closeRules, findsOneWidget,
            reason: 'Rules button must open a dismissible dialog for $id');
        await tester.tap(closeRules);
        await tester.pump(const Duration(seconds: 1));
        if (find.byTooltip('New game').evaluate().isNotEmpty) {
          await tester.tap(find.byTooltip('New game'));
        } else if (id == 'five_card_draw') {
          expect(find.text('New table'), findsOneWidget);
          await tester.tap(find.text('New table'));
        }
      }
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
