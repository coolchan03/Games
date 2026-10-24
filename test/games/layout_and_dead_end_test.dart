import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/common/game_kit.dart';
import 'package:puzzle/ui/features/games/common/solitaire_kit.dart';
import 'package:puzzle/ui/features/games/forty_thieves/forty_thieves_engine.dart';

void main() {
  group('Forty Thieves dead ends', () {
    FortyThievesGame blocked() {
      final game = FortyThievesGame()
        ..stock = []
        ..waste = [];
      // Ten lone cards, no aces and no two of the same suit one rank apart.
      final ranks = [Rank.two, Rank.four, Rank.six, Rank.eight, Rank.ten];
      game.tableau = [
        for (final suit in [Suit.clubs, Suit.diamonds])
          for (final rank in ranks) [SCard(PlayingCard(rank, suit), up: true)],
      ];
      return game;
    }

    test('detects that no move is left once the stock is empty', () {
      expect(blocked().noMovesLeft, isTrue);
    });

    test('is not a dead end while a card can still be played', () {
      final game = blocked()..waste = [PlayingCard(Rank.three, Suit.clubs)];
      expect(game.noMovesLeft, isFalse); // 3♣ goes on 4♣
      expect(FortyThievesGame().noMovesLeft, isFalse); // stock left
    });
  });

  testWidgets('GameScaffold offers Undo and New deal at a dead end',
      (tester) async {
    var deadEnd = false, undone = 0, dealt = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return GameScaffold(
          title: 'Test',
          rules: '',
          onNewGame: () => dealt++,
          deadEnd: deadEnd,
          onUndo: () => undone++,
          children: const [Text('board')],
        );
      }),
    ));
    expect(find.text('No moves left'), findsNothing);
    update(() => deadEnd = true);
    await tester.pumpAndSettle();
    expect(find.text('No moves left'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('No moves left'), findsNothing);

    // It appears again only after the position stops being a dead end.
    update(() => deadEnd = false);
    await tester.pump();
    update(() => deadEnd = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New deal'));
    await tester.pumpAndSettle();
    expect(dealt, 1);
  });

  group('Screen-size layout', () {
    test('phones keep the preferred width', () {
      expect(contentWidthFor(const Size(360, 780), 640), 640);
      expect(contentWidthFor(const Size(780, 360), 640), 640);
    });

    test('tablets and desktops use the extra room', () {
      // Portrait tablet: nearly the full width.
      expect(contentWidthFor(const Size(800, 1280), 640), closeTo(752, .1));
      // Landscape tablet: a square board and its controls fit the height.
      expect(contentWidthFor(const Size(1280, 800), 640), 580);
      // Wide card tables grow with the width.
      expect(contentWidthFor(const Size(1280, 800), 820), closeTo(1203.2, .1));
      expect(contentWidthFor(const Size(3000, 2000), 820), 1400);
    });

    testWidgets('cards grow on tablets and in landscape', (tester) async {
      late double phone, landscape, tablet;
      Future<double> measure(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        late double w;
        await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
          w = cardMaxWidth(context, 72);
          return const SizedBox();
        })));
        return w;
      }

      addTearDown(tester.view.reset);
      phone = await measure(const Size(360, 780));
      landscape = await measure(const Size(780, 360));
      tablet = await measure(const Size(1280, 800));
      expect(phone, 72);
      expect(landscape, greaterThan(phone));
      expect(tablet, greaterThan(landscape));
    });
  });
}
