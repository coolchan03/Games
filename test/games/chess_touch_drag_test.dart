import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/chess/chess_screen.dart';

void main() {
  testWidgets('chess supports long-press drag from e2 to e4 on touch',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChessScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    final from = find.bySemanticsLabel('e2 white pawn');
    final to = find.bySemanticsLabel('e4');
    expect(from, findsOneWidget);
    expect(to, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.bySemanticsLabel('e4 white pawn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
