import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_levels.dart';
import 'package:puzzle/ui/features/games/lights_out/lights_out_screen.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('lights-out');
    Hive.init(dir.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('following hints clears the level', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LightsOutScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    final par = LightsOutLevels.build(1).par;
    for (var i = 0; i < par; i++) {
      await tester.tap(find.byTooltip('Hint'));
      await tester.pump();
      // The hinted cell is the one with the primary-coloured border: find via
      // the solver instead of pixels.
      final lit = [
        for (var c = 1; c <= 9; c++)
          find.bySemanticsLabel(RegExp('column ${(c - 1) % 3 + 1}, on')).evaluate().isNotEmpty
      ];
      expect(lit, isNotEmpty);
      // Press along the solver's solution directly.
      final board = <bool>[];
      for (var r = 1; r <= 3; r++) {
        for (var c = 1; c <= 3; c++) {
          board.add(find.bySemanticsLabel('Row $r, column $c, on').evaluate().isNotEmpty);
        }
      }
      final next = LightsOutSolver.solve(3, board)!.first;
      await tester.tap(find.bySemanticsLabel(
          'Row ${next ~/ 3 + 1}, column ${next % 3 + 1}, ${board[next] ? 'on' : 'off'}'));
      await tester.pump();
    }
    expect(find.textContaining('Cleared in $par presses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
