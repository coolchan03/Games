import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/aces_up/aces_up_screen.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/common/game_kit.dart';
import 'package:puzzle/ui/features/games/common/solitaire_kit.dart';
import 'package:puzzle/ui/features/games/freecell/freecell_engine.dart';
import 'package:puzzle/ui/features/games/klondike/klondike_engine.dart';
import 'package:puzzle/ui/features/games/spider/spider_engine.dart';

void main() {
  group('Solitaire dead-end detection', () {
    test('Klondike considers future stock plays and valid tableau moves', () {
      final game = KlondikeGame(random: Random(1));
      game.stock.clear();
      game.waste.clear();
      game.tableau = List.generate(7, (_) => <SCard>[]);
      game.foundations = List.generate(4, (_) => <SCard>[]);
      expect(game.noMovesLeft, isTrue);
      game.stock.add(SCard(PlayingCard(Rank.ace, Suit.hearts)));
      expect(game.noMovesLeft, isFalse);
      game.stock.clear();
      game.tableau[0].add(SCard(PlayingCard(Rank.king, Suit.hearts), up: true));
      game.tableau[1].add(SCard(PlayingCard(Rank.queen, Suit.spades), up: true));
      expect(game.noMovesLeft, isFalse);
    });

    test('Spider warns when no deal or meaningful run transfer is possible', () {
      final game = SpiderGame(random: Random(3));
      game.stock.clear();
      game.tableau = List.generate(10, (_) => <SCard>[]);
      expect(game.noMovesLeft, isTrue);
      game.tableau[0].add(SCard(PlayingCard(Rank.king, Suit.hearts), up: true));
      expect(game.noMovesLeft, isTrue);
      game.tableau[1].add(SCard(PlayingCard(Rank.queen, Suit.hearts), up: true));
      expect(game.noMovesLeft, isFalse);
    });

    test('FreeCell detects legal moves to empty free cells', () {
      final game = FreeCellGame(1);
      game.tableau = List.generate(8, (_) => <SCard>[]);
      game.cells = List<SCard?>.filled(4, null);
      game.foundations = List.generate(4, (_) => <SCard>[]);
      expect(game.noMovesLeft, isTrue);
      game.tableau[0].add(SCard(PlayingCard(Rank.eight, Suit.spades), up: true));
      expect(game.noMovesLeft, isFalse);
    });

    test('Aces Up can drag a card directly into a chosen empty pile', () {
      final game = AcesUpGame(random: Random(4));
      for (final pile in game.piles) { pile.clear(); }
      game.piles[0].addAll([
        PlayingCard(Rank.queen, Suit.diamonds),
        PlayingCard(Rank.king, Suit.clubs),
      ]);
      expect(game.canMoveToEmpty(0, 1), isTrue);
      expect(game.canMoveToEmpty(0, 0), isFalse);
      expect(game.moveToEmpty(0, 1), isTrue);
      expect(game.piles[0].length, 1);
      expect(game.piles[1].single.rank, Rank.king);
      game.undo();
      expect(game.piles[0].length, 2);
      expect(game.piles[1], isEmpty);
    });
  });

  testWidgets('shared solitaire cards drag onto permitted piles', (tester) async {
    var accepted = -1;
    var allowed = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CardColumn(
              cards: [SCard(PlayingCard(Rank.seven, Suit.hearts), up: true)],
              width: 72,
              maxHeight: 110,
              dragDataAt: (i) => 7,
            ),
            const SizedBox(width: 90),
            PileSlot(
              top: null,
              width: 72,
              label: 'Drop',
              canAccept: (source) => allowed && source == 7,
              onAccept: (source) => accepted = source as int,
            ),
          ]),
        ),
      ),
    ));
    final start = tester.getTopLeft(find.byType(CardColumn)) +
        const Offset(30, 35);
    final end = tester.getCenter(find.byType(PileSlot));
    Future<void> drag() async {
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(start + const Offset(25, 0));
      await tester.pump();
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }
    await drag();
    expect(accepted, 7);
    accepted = -1;
    allowed = false;
    await drag();
    expect(accepted, -1);
  });

  testWidgets('card games use available width on compact landscape phones',
      (tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    double width = 0;
    await tester.pumpWidget(MaterialApp(
      home: GameScaffold(
        title: 'Landscape Solitaire',
        rules: 'Move cards.',
        onNewGame: () {},
        children: [
          LayoutBuilder(builder: (context, bounds) {
            width = bounds.maxWidth;
            return const SizedBox(height: 40);
          }),
        ],
      ),
    ));
    await tester.pump();
    expect(width, greaterThan(700));
  });
}
