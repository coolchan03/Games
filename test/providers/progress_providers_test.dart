import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/providers/user_providers.dart';

void main() {
  late Directory dir;
  late UserRepository repo;

  setUpAll(() {
    Hive.registerAdapter(UserDataAdapter());
    Hive.registerAdapter(GameStreakAdapter());
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('progress_test');
    Hive.init(dir.path);
    repo = UserRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    return c;
  }

  test('completing a game awards XP, logs activity and unlocks a milestone', () async {
    final c = container();
    final id = allGamesMetadata.first.id;
    await c.read(gameStreakNotifierProvider.notifier).completeGame(id, xpAmount: 20);

    final user = c.read(userDataNotifierProvider);
    expect(user.totalSolved, 1);
    expect(user.xp, greaterThanOrEqualTo(20));
    expect(c.read(activityLogProvider)[engine.dayKey(DateTime.now())], 1);
    expect(c.read(milestoneToastProvider).map((m) => m.id), contains('first_solve'));
    expect(repo.getActivityLog().values.single, 1);

    // Idempotent within a day.
    await c.read(gameStreakNotifierProvider.notifier).completeGame(id);
    expect(c.read(userDataNotifierProvider).totalSolved, 1);
  });

  test('daily challenge bonus is paid once per day', () async {
    final c = container();
    final id = c.read(dailyChallengeIdProvider)!;
    await c.read(gameStreakNotifierProvider.notifier).completeGame(id, xpAmount: 20);
    expect(c.read(userDataNotifierProvider).xp, 20 + engine.dailyChallengeBonusXp);
    expect(c.read(dailyChallengeDoneProvider), isTrue);
    expect(repo.getDailyClaim(), engine.dayKey(DateTime.now()));
  });

  test('stale streaks reset even when the game was not solved on its last day', () async {
    final old = DateTime.now().subtract(const Duration(days: 5));
    await repo.saveGameStreak(GameStreak(
        gameId: 'g', currentStreak: 7, lastSolvedDate: old, solvedToday: false));
    final c = container();
    c.read(gameStreakNotifierProvider.notifier).applyDailyReset();
    expect(c.read(gameStreakNotifierProvider)['g']!.currentStreak, 0);
    expect(repo.getGameStreak('g').currentStreak, 0);
  });

  test('yesterday keeps the streak but clears solvedToday', () async {
    final y = DateTime.now().subtract(const Duration(days: 1));
    await repo.saveGameStreak(GameStreak(
        gameId: 'g', currentStreak: 3, lastSolvedDate: y, solvedToday: true));
    final c = container();
    c.read(gameStreakNotifierProvider.notifier).applyDailyReset();
    final s = c.read(gameStreakNotifierProvider)['g']!;
    expect(s.currentStreak, 3);
    expect(s.solvedToday, isFalse);
  });

  test('backup round-trips progress and rejects bad input without changes', () async {
    final c = container();
    final id = allGamesMetadata.first.id;
    await c.read(gameStreakNotifierProvider.notifier).completeGame(id, xpAmount: 50);
    await c.read(userDataNotifierProvider.notifier).toggleFavorite(id);
    final text = c.read(backupServiceProvider).export();

    await repo.clearAll();
    final c2 = container();
    await c2.read(backupServiceProvider).import(text);
    expect(c2.read(userDataNotifierProvider).xp, greaterThanOrEqualTo(50));
    expect(c2.read(userDataNotifierProvider).favoriteGameIds, [id]);
    expect(c2.read(gameStreakNotifierProvider).containsKey(id), isTrue);
    expect(c2.read(activityLogProvider), isNotEmpty);

    final before = c2.read(userDataNotifierProvider).xp;
    await expectLater(c2.read(backupServiceProvider).import('garbage'),
        throwsA(isA<engine.BackupException>()));
    expect(c2.read(userDataNotifierProvider).xp, before);
  });
}
