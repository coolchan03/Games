import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/main.dart';
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/providers/ui_scale_provider.dart';
import 'package:puzzle/providers/user_providers.dart';

void main() {

  late Directory dir;
  late UserRepository repo;

  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('shell-test');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserDataAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GameStreakAdapter());
      if (!Hive.isBoxOpen('classic_games_v1')) {
        await Hive.openBox<String>('classic_games_v1', bytes: Uint8List(0));
      }
      repo = UserRepository();
      await repo.init();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(repo)],
      child: const MyApp(),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('largest interface size on a small phone does not overflow',
      (tester) async {
    await open(tester, const Size(360, 640));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() =>
        container.read(uiSizeProvider.notifier).choose(UiSize.extraLarge));
    await tester.pump(const Duration(milliseconds: 300));
    for (final tab in ['Stats', 'Settings', 'Games']) {
      await tester.tap(find.text(tab));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('phone: bottom navigation, daily challenge, stats and settings',
      (tester) async {
    await open(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('daily_challenge_card')), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ACTIVITY'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('backup_export')), 300,
        scrollable: find.byType(Scrollable).last);
    expect(find.byKey(const ValueKey('backup_import')), findsOneWidget);

    // Back on Games the library is still there (tab state kept alive).
    await tester.tap(find.text('Games'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('daily_challenge_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet: navigation rail replaces the bottom bar', (tester) async {
    await open(tester, const Size(1024, 768));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unlocking a milestone shows a toast', (tester) async {
    await open(tester, const Size(390, 844));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(gameStreakNotifierProvider.notifier)
        .completeGame('peg_solitaire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Achievement unlocked'), findsOneWidget);
    expect(container.read(milestoneToastProvider), isEmpty);
  });
}
