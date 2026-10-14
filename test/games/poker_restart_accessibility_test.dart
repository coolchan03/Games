import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/poker/poker_screen.dart';
import 'package:puzzle/ui/features/games/poker/poker_table.dart';

void main() {
  late Directory hiveDir;
  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('poker-restart-');
    Hive.init(hiveDir.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('Draw poker restart stays available without scrolling', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: PokerScreen(variant: PokerVariant.draw),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    final restart = find.byTooltip('New game');
    expect(restart, findsOneWidget);
    await tester.tap(restart);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
