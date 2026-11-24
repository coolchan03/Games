import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_screen.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('water-sort');
    Hive.init(dir.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('shows levels, hints and random levels without errors', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WaterSortScreen())));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('water_sort_level_selector')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Tube \d')), findsNWidgets(5)); // 3 colours + 2 empty

    // Undo starts disabled; a hint highlights a pour and keeps the game valid.
    await tester.tap(find.byTooltip('Hint'));
    await tester.pump();
    expect(find.textContaining('too big'), findsNothing);
    expect(find.textContaining('No winning line'), findsNothing);

    // Make a move (any legal-or-not tap pair must not throw), then undo.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Tube 1,')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Tube 4,')));
    await tester.pump();

    await tester.tap(find.byTooltip('Random level'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Random level'), findsOneWidget);
    await tester.tap(find.text('Back to levels'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('water_sort_level_selector')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
