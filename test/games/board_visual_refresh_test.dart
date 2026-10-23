import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/connect_four/connect_four_screen.dart';
import 'package:puzzle/ui/features/games/mancala/mancala_screen.dart';
import 'package:puzzle/ui/features/games/oware/oware_screen.dart';
import 'package:puzzle/ui/features/games/tic_tac_toe/tic_tac_toe_screen.dart';

Future<void> _phone(WidgetTester tester, Widget screen,
    {Size size = const Size(360, 780)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
}

void main() {
  testWidgets('Tic-Tac-Toe draws X, then the computer answers', (tester) async {
    await _phone(tester, const TicTacToeScreen());
    await tester.tap(find.byKey(const ValueKey('tic_tac_toe_cell_4')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('Square 5: X'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'O$')), findsOneWidget);
    expect(find.text('You (X) to move'), findsOneWidget);
  });

  testWidgets('Connect Four drops into the tapped column in two-player mode',
      (tester) async {
    await _phone(tester, const ConnectFourScreen());
    await tester.tap(find.text('2 Players'));
    await tester.pump();
    expect(find.text('Red to move'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connect_four_column_3')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Yellow to move'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mancala sows from a tapped pit on a phone in both orientations',
      (tester) async {
    for (final size in const [Size(360, 780), Size(780, 360)]) {
      await tester.pumpWidget(const SizedBox()); // fresh game each time
      await _phone(tester, const MancalaScreen(), size: size);
      await tester.tap(find.text('2 Players'));
      await tester.pump();
      expect(find.text('Player 1 to move'), findsOneWidget);
      // Pit 3 holds four seeds: the last lands in the store, so play again.
      await tester.tap(find.byKey(const ValueKey('mancala_pit_2')));
      await tester.pump();
      expect(find.text('Player 1 to move'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^P1: 1 seeds')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mancala_pit_0')));
      await tester.pump();
      expect(find.text('Player 2 to move'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Oware renders its wooden board at phone width', (tester) async {
    await _phone(tester, const OwareScreen());
    await tester.pump();
    expect(find.byKey(const ValueKey('oware_pit_0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
