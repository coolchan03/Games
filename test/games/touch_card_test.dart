import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/card_face.dart';
import 'package:puzzle/ui/features/games/shared/playing_cards.dart';
import 'package:puzzle/ui/features/games/shared/touch_cards.dart';

void main() {
  testWidgets('card is playable by tap without long-pressing', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TouchCard<int>(
      card: PlayingCard.parse('7d'), data: 3, onTap: () => taps++,
    ))));
    await tester.tap(find.byType(CardFace).first);
    expect(taps, 1);
  });

  testWidgets('hold-and-drag accepts a legal card only', (tester) async {
    int? received;
    var allowed = true;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child:
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        TouchCard<int>(card: PlayingCard.parse('7d'), data: 3,
            onTap: () {}),
        CardDropZone<int>(
          canAccept: (i) => allowed && i == 3,
          onAccept: (i) => received = i,
          child: const SizedBox(width: 120, height: 120, child: Text('Drop here')),
        ),
      ]),
    ))));
    final start = tester.getCenter(find.byType(TouchCard<int>));
    final end = tester.getCenter(find.text('Drop here'));
    var gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    expect(received, 3);
    received = null;
    allowed = false;
    gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    expect(received, isNull);
  });
}
