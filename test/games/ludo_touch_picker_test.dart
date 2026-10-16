import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/ludo/ludo_screen.dart';

void main() {
  testWidgets('Ludo provides four large labeled horse controls on phone',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LudoScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 1; i <= 4; i++) {
      final finder = find.byKey(ValueKey('ludo_horse_$i'), skipOffstage: false);
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
