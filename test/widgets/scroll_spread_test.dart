import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/widgets/scroll_spread.dart';

void main() {
  Widget host(double height, int items) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: height,
            child: ScrollSpread(children: [
              for (var i = 0; i < items; i++) SizedBox(key: ValueKey('c$i'), height: 100, width: 50),
              // Children without intrinsic sizes must work (GridView, LayoutBuilder).
              GridView.count(shrinkWrap: true, crossAxisCount: 2, children: const [Text('a'), Text('b')]),
              LayoutBuilder(builder: (_, __) => const SizedBox(height: 10)),
            ]),
          ),
        ),
      );

  testWidgets('spreads children when there is room and scrolls when there is not', (tester) async {
    await tester.pumpWidget(host(900, 2));
    expect(tester.takeException(), isNull);
    final gap = tester.getTopLeft(find.byKey(const ValueKey('c0'))).dy;
    expect(gap, greaterThan(10)); // spaceEvenly leaves a leading gap

    await tester.pumpWidget(host(300, 6));
    expect(tester.takeException(), isNull); // no overflow: it scrolls instead
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
