import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/home/widgets/table_texture.dart';

void main() {
  const categories = [
    'ALL',
    'CARD',
    'LOGIC',
    'BOARD',
    'MATH',
    'WORD',
    'MEMORY',
    'ATTENTION',
    'SPATIAL',
    'UNKNOWN',
  ];

  for (final brightness in Brightness.values) {
    testWidgets('every category background paints ($brightness)',
        (tester) async {
      for (final category in categories) {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: TableTextureBackground(
            category: category,
            child: const Text('games'),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: category);
        expect(find.text('games'), findsOneWidget);
      }
    });
  }

  test('a background repaints only when its category or mode changes', () {
    final card = TableTexturePainter(category: 'CARD', dark: false);
    expect(
        card.shouldRepaint(TableTexturePainter(category: 'CARD', dark: false)),
        isFalse);
    expect(
        card.shouldRepaint(TableTexturePainter(category: 'WORD', dark: false)),
        isTrue);
    expect(
        card.shouldRepaint(TableTexturePainter(category: 'CARD', dark: true)),
        isTrue);
  });
}
