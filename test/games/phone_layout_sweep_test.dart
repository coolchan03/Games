import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/design_system.dart';

/// Opens every game on a small portrait phone at the app's largest text size
/// and fails on any layout overflow. Set SWEEP_REPORT=path to write a summary.
/// SWEEP_SCALE overrides the text scale (default 1.5 = "Extra large").
void main() {
  late Directory tempHive;
  final scale = double.tryParse(Platform.environment['SWEEP_SCALE'] ?? '') ?? 1.5;
  final failures = <String, String>{};

  setUpAll(() async {
    tempHive = await Directory.systemTemp.createTemp('layout-sweep-');
    Hive.init(tempHive.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await tempHive.delete(recursive: true);
    final report = Platform.environment['SWEEP_REPORT'];
    if (report != null) {
      File(report).writeAsStringSync(failures.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'));
    }
  });

  // SWEEP=1 enables this slow audit; SWEEP_SHARD=i/n splits it across runs.
  final enabled = Platform.environment['SWEEP'] == '1';
  final shard = (Platform.environment['SWEEP_SHARD'] ?? '0/1').split('/');
  final shardIndex = int.parse(shard[0]), shardCount = int.parse(shard[1]);
  final only = (Platform.environment['SWEEP_ONLY'] ?? '').split(',').where((e) => e.isNotEmpty).toSet();
  final games = [
    for (var i = 0; i < allGamesMetadata.length; i++)
      if (only.isEmpty ? i % shardCount == shardIndex : only.contains(allGamesMetadata[i].id))
        allGamesMetadata[i],
  ];

  for (final game in games) {
    testWidgets('${game.id} fits a 360x640 phone at ${scale}x text', (tester) async {
      if (!enabled) return;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        final where = RegExp(r'file:///\S+?(lib/\S+)').firstMatch(details.toString());
        overflows.add('${text.split('\n').first} @ ${where?.group(1) ?? '?'}');
      };

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: DesignSystem.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(builder: game.builder),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      // Restore the framework handler before asserting (flutter_test requires it).
      FlutterError.onError = previous;
      tester.takeException();

      if (overflows.isNotEmpty) failures[game.id] = overflows.toSet().take(3).join(' | ');
      expect(overflows.toSet(), isEmpty, reason: 'overflow in ${game.id}');
    });
  }
}
