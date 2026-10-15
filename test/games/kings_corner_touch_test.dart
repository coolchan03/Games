import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/kings_corner/kings_corner_screen.dart';
import 'package:puzzle/ui/features/games/shared/touch_cards.dart';

void main() {
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('king-drag-');
    Hive.init(temp.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  testWidgets('Kings Corner exposes drag sources and eight targets on phone',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: KingsCornerScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    final reveal = find.text('View Player 1 cards');
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump();
    expect(find.byType(TouchCard<(bool, int)>), findsWidgets);
    expect(find.byType(CardDropZone<(bool, int)>), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });
}
