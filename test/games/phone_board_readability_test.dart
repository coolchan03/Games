import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/solitaire_kit.dart';
import 'package:puzzle/ui/features/games/common/sowing_board.dart';
import 'package:puzzle/ui/features/games/klondike/klondike_screen.dart';
import 'package:puzzle/ui/features/games/mancala/mancala_screen.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Klondike keeps readable card widths on a narrow phone',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: KlondikeScreen()));
    final columns = find.byType(CardColumn);
    expect(columns, findsNWidgets(7));
    expect(tester.getSize(columns.first).width, greaterThanOrEqualTo(60));
    expect(find.textContaining('Swipe sideways'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mancala uses larger pits and an accessible horizontal board',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: MancalaScreen()));
    expect(find.byType(SowingPit), findsNWidgets(12));
    expect(tester.getSize(find.byType(SowingPit).first).width,
        greaterThanOrEqualTo(60));
    expect(find.textContaining('Swipe sideways'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
