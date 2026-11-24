import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/widgets/min_height_scroll.dart';

void main() {
  Widget host(double height) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: height,
            child: MinHeightScroll(
              minHeight: 500,
              child: Column(children: [
                const SizedBox(height: 300),
                Expanded(child: Container(key: const ValueKey('play'))),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ),
      );

  testWidgets('short slots scroll, tall slots are untouched', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(400)); // 300 + 100 leaves no room: would overflow
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('play'))).height, 100);

    await tester.pumpWidget(host(700));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('play'))).height, 300);
  });
}
