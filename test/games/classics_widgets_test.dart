import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/providers/library_style_provider.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/library_theme.dart';
import 'package:puzzle/ui/features/games/shared/card_face.dart';
import 'package:puzzle/ui/features/games/shared/game_page.dart';
import 'package:puzzle/ui/features/games/chess/chess_screen.dart';
import 'package:puzzle/ui/features/games/poker/poker_screen.dart';
import 'package:puzzle/ui/features/games/poker/poker_table.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/mahjong_screen.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Layout tests run in FakeAsync. Use Hive's real in-memory backend so a
  // computer turn cannot leave filesystem futures pending across test zones.
  // Disk durability is covered separately by classics_persistence_test.dart.
  setUpAll(() async {
    await Hive.openBox<String>('classic_games_v1', bytes: Uint8List(0));
  });
  tearDownAll(() async {
    await Hive.close().timeout(const Duration(seconds: 20));
  });
  final screens = <String, Widget Function()>{
    'chess': () => const ChessScreen(),
    'holdem': () => const PokerScreen(),
    'draw': () => const PokerScreen(variant: PokerVariant.draw),
    'mahjong': () => const MahjongSolitaireScreen(),
    'detective': () => const DetectiveCasebookScreen(),
  };
  for (final entry in screens.entries) {
    for (final width in [320.0, 800.0]) {
      testWidgets('${entry.key} has no layout errors at width $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: applyLibraryStyle(DesignSystem.lightTheme, LibraryStyle.colorful),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.5 : 1)),
            child: child!),
          home: entry.value(),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(GamePage), findsOneWidget);
        if (entry.key == 'holdem' || entry.key == 'draw') {
          final visibleFaces = tester.widgetList<CardFace>(find.byType(CardFace));
          expect(visibleFaces.where((face) => face.card != null).every((face) => face.hidden), true,
            reason: 'Private cards must be concealed on entry');
        }
        if (const bool.fromEnvironment('CAPTURE')) {
          await expectLater(find.byType(GamePage), matchesGoldenFile(
            '../../build/classics-screenshots/${entry.key}-${width.toInt()}.png'));
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
