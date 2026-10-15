import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/game_page.dart';
import 'package:puzzle/ui/features/games/common/game_kit.dart';

void main() {
  testWidgets('game page has an in-content rules guide', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GamePage(
      title: 'Example cards',
      rules: 'Goal: empty your hand. Controls: tap a legal card.',
      children: [Text('Cards')],
    )));
    expect(find.text('How to play'), findsOneWidget);
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Goal: empty your hand'), findsOneWidget);
  });

  testWidgets('classic games expose their guide without opening the app bar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: GameScaffold(
      title: 'Sample classic',
      rules: 'Move: tap the board. Win: reach the finish.',
      onNewGame: () {},
      children: const [Text('Board')],
    )));
    expect(find.text('How to play'), findsOneWidget);
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Win: reach the finish'), findsOneWidget);
  });
}
