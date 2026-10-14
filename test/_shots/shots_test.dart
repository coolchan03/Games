import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';

void main() {
  final ids = (Platform.environment['SHOTS'] ?? 'ludo,backgammon').split(',');
  for (final id in ids) {
    testWidgets('shot $id', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      final meta = allGamesMetadata.firstWhere((g) => g.id == id);
      await tester.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(theme: ThemeData(useMaterial3: true), home: Builder(builder: meta.builder))));
      for (var i = 0; i < 8; i++) { await tester.pump(const Duration(milliseconds: 600)); }
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1.5);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/claude-0/-home-user-Games/da079d9a-6076-56ca-acdd-ae73a897b4fe/scratchpad/$id.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
