import 'dart:async';
import 'dart:math' as math;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_data.dart';
import '../data/models/game_streak.dart';
import '../data/repositories/user_repository.dart';
import '../domain/progress_engine.dart' as engine;
import 'progress_providers.dart';

part 'user_providers.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository();
}

@Riverpod(keepAlive: true)
class UserDataNotifier extends _$UserDataNotifier {
  @override
  UserData build() {
    return ref.read(userRepositoryProvider).getUserData();
  }

  int calculateLevel(int xp) => engine.levelForXp(xp);

  int xpForLevel(int level) => engine.xpForLevel(level);

  /// Fire-and-forget persistence that can never surface as an unhandled
  /// async error; the in-memory state stays authoritative for this session.
  void _persist(UserData data) {
    unawaited(ref
        .read(userRepositoryProvider)
        .saveUserData(data)
        .catchError((Object _) {}));
  }

  Future<void> addXp(int amount) async {
    final newXp = state.xp + amount;
    final newLevel = calculateLevel(newXp);
    final newState = state.copyWith(xp: newXp, level: newLevel);
    state = newState;
    _persist(newState);
  }

  Future<void> incrementTotalSolved() async {
    final newState = state.copyWith(totalSolved: (state.totalSolved ?? 0) + 1);
    state = newState;
    _persist(newState);
  }

  Future<void> updateSuperStreak(Map<String, GameStreak> streaks) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastSuperStreak = state.lastSuperStreakDate;
    final lastNormalized = lastSuperStreak != null
        ? DateTime(lastSuperStreak.year, lastSuperStreak.month, lastSuperStreak.day)
        : DateTime.fromMillisecondsSinceEpoch(0);

    if (lastNormalized == today) return;

    final solvedTodayCount = streaks.values.where((s) => s.solvedToday).length;
    if (solvedTodayCount >= 1) {
      int newStreak = 1;
      if (engine.calendarDaysBetween(lastNormalized, today) == 1) {
        newStreak = (state.superStreak ?? 0) + 1;
      }

      final newState = state.copyWith(
        superStreak: newStreak,
        lastSuperStreakDate: now,
      );
      state = newState;
      _persist(newState);
    }
  }

  void refreshSuperStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastSuperStreak = state.lastSuperStreakDate;
    if (lastSuperStreak == null) return;

    final lastNormalized = DateTime(lastSuperStreak.year, lastSuperStreak.month, lastSuperStreak.day);
    final daysSince = engine.calendarDaysBetween(lastNormalized, today);

    if (daysSince > 1 && (state.superStreak ?? 0) > 0) {
      final newState = state.copyWith(superStreak: 0);
      state = newState;
      _persist(newState);
    }
  }

  Future<void> toggleFavorite(String gameId) async {
    final favorites = List<String>.from(state.favoriteGameIds ?? []);
    if (favorites.contains(gameId)) {
      favorites.remove(gameId);
    } else {
      favorites.add(gameId);
    }
    final newState = state.copyWith(favoriteGameIds: favorites);
    state = newState;
    _persist(newState);
  }

  Future<void> toggleHideGame(String gameId) async {
    final hidden = List<String>.from(state.hiddenGameIds ?? []);
    if (hidden.contains(gameId)) {
      hidden.remove(gameId);
    } else {
      hidden.add(gameId);
    }
    final newState = state.copyWith(hiddenGameIds: hidden);
    state = newState;
    _persist(newState);
  }

  Future<void> setTrialMode(bool enabled) async {
    final newState = state.copyWith(isTrialModeEnabled: enabled);
    state = newState;
    _persist(newState);
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    final newState = state.copyWith(isKeepScreenAwakeEnabled: enabled);
    state = newState;
    _persist(newState);
  }

  /// Replaces in-memory state after a backup import.
  void replace(UserData data) => state = data;
}

@Riverpod(keepAlive: true)
class GameStreakNotifier extends _$GameStreakNotifier {
  @override
  Map<String, GameStreak> build() {
    final streaks = ref.read(userRepositoryProvider).getAllGameStreaks();
    return {for (var s in streaks) s.gameId: s};
  }

  /// Clears "solved today" flags from earlier days and zeroes streaks that
  /// missed a day. Streaks are reset even when the game was not solved on its
  /// last active day, so a stale count is never displayed after a long break.
  void applyDailyReset() {
    final today = engine.dayOf(DateTime.now());
    final updated = Map<String, GameStreak>.from(state);
    final toSave = <GameStreak>[];

    for (final entry in state.entries) {
      final streak = entry.value;
      final lastSolved = engine.dayOf(streak.lastSolvedDate);
      final isNeverSolved = streak.lastSolvedDate.millisecondsSinceEpoch == 0;
      var next = streak;
      if (streak.solvedToday && lastSolved != today) {
        next = next.copyWith(solvedToday: false);
      }
      if (!isNeverSolved &&
          next.currentStreak > 0 &&
          engine.isStreakBroken(lastSolved, today)) {
        next = next.copyWith(currentStreak: 0);
      }
      if (next != streak) {
        updated[entry.key] = next;
        toSave.add(next);
      }
    }

    if (toSave.isNotEmpty) {
      state = updated;
      unawaited(ref
          .read(userRepositoryProvider)
          .saveAllGameStreaks(toSave)
          .catchError((Object _) {}));
    }
  }

  GameStreak getStreak(String gameId) {
    return state[gameId] ?? GameStreak.initial(gameId);
  }

  /// Records a solve. Returns true once the completion is recorded (also when
  /// the game was already completed today). Awards a one-time daily-challenge
  /// bonus, logs activity and reports newly unlocked milestones.
  Future<bool> completeGame(String gameId, {int xpAmount = 20}) async {
    final now = DateTime.now();
    final today = engine.dayOf(now);
    final repo = ref.read(userRepositoryProvider);

    final currentStreak = getStreak(gameId);
    final lastNormalized = engine.dayOf(currentStreak.lastSolvedDate);
    if (currentStreak.solvedToday && lastNormalized == today) return true;

    final neverSolved = currentStreak.lastSolvedDate.millisecondsSinceEpoch == 0;
    final gap = engine.calendarDaysBetween(lastNormalized, today);
    final newStreakCount = neverSolved
        ? 1
        : gap == 1
            ? currentStreak.currentStreak + 1
            : gap > 1
                ? 1
                : math.max(currentStreak.currentStreak, 1);

    final newStreak = currentStreak.copyWith(
      currentStreak: newStreakCount,
      lastSolvedDate: now,
      solvedToday: true,
    );

    final before = buildProgressSnapshot(
        ref.read(userDataNotifierProvider), state, ref.read(activityLogProvider));

    // Daily challenge: one bonus per calendar day.
    final challengeId = ref.read(dailyChallengeIdProvider);
    final claimKey = engine.dayKey(today);
    final bonus = challengeId == gameId && repo.getDailyClaim() != claimKey
        ? engine.dailyChallengeBonusXp
        : 0;

    final user = ref.read(userDataNotifierProvider);
    final newXp = user.xp + xpAmount + bonus;
    final newUserData = user.copyWith(
      xp: newXp,
      level: engine.levelForXp(newXp),
      totalSolved: (user.totalSolved ?? 0) + 1,
    );

    state = {...state, gameId: newStreak};
    ref.read(userDataNotifierProvider.notifier).replace(newUserData);
    ref.read(activityLogProvider.notifier).record(now);
    if (bonus > 0) unawaited(repo.saveDailyClaim(claimKey));

    final after =
        buildProgressSnapshot(newUserData, state, ref.read(activityLogProvider));
    final unlocked = engine.newlyUnlocked(before, after);
    if (unlocked.isNotEmpty) {
      ref.read(milestoneToastProvider.notifier).state = unlocked;
    }

    try {
      await repo.saveGameCompletion(newUserData, newStreak);
    } catch (_) {
      // Progress stays in memory for this session; storage errors are logged
      // by the repository and must not fail the game that just ended.
    }
    await ref.read(userDataNotifierProvider.notifier).updateSuperStreak(state);
    return true;
  }

  void refreshStatus() {
    ref.read(userDataNotifierProvider.notifier).refreshSuperStreak();
    applyDailyReset();
  }
}
