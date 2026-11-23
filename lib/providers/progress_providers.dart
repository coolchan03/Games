import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_registry.dart';
import '../data/models/game_streak.dart';
import '../data/models/user_data.dart';
import '../domain/progress_engine.dart' as engine;
import 'game_session_provider.dart';
import 'user_providers.dart';

/// Current calendar day; the app shell refreshes it when midnight passes so
/// day-dependent providers (daily challenge) recompute.
final todayProvider =
    StateProvider<DateTime>((ref) => engine.dayOf(DateTime.now()));

/// Per-day solve counts, persisted in the app meta box.
class ActivityLogNotifier extends StateNotifier<engine.ActivityLog> {
  ActivityLogNotifier(this._ref)
      : super(_ref.read(userRepositoryProvider).getActivityLog());
  final Ref _ref;

  void record(DateTime when) {
    state = engine.recordActivity(state, when);
    _ref.read(userRepositoryProvider).saveActivityLog(state);
  }
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, engine.ActivityLog>(
        (ref) => ActivityLogNotifier(ref));

/// Aggregates the numbers milestones are evaluated against. A plain function
/// (not a provider read) so notifiers can call it with their own fresh state
/// without creating a provider cycle.
engine.ProgressSnapshot buildProgressSnapshot(
    UserData user, Map<String, GameStreak> streaks, engine.ActivityLog log) {
  final categoryById = {for (final g in allGamesMetadata) g.id: g.category};
  final played = streaks.keys.where(categoryById.containsKey).toList();
  final bestDay = log.values.fold<int>(0, (m, v) => v > m ? v : m);
  return engine.ProgressSnapshot(
    xp: user.xp,
    totalSolved: user.totalSolved ?? 0,
    level: user.level,
    distinctGamesPlayed: played.length,
    categoriesPlayed: {for (final id in played) categoryById[id]}.length,
    bestDayStreak: engine.longestActiveStreak(log),
    activeDays: log.length,
    bestSingleDay: bestDay,
  );
}

final progressSnapshotProvider = Provider<engine.ProgressSnapshot>((ref) =>
    buildProgressSnapshot(ref.watch(userDataNotifierProvider),
        ref.watch(gameStreakNotifierProvider), ref.watch(activityLogProvider)));

/// The featured game of the day (same for every player on a given date).
final dailyChallengeIdProvider = Provider<String?>((ref) {
  final day = ref.watch(todayProvider);
  return engine.dailyChallengeGameId(allGamesMetadata.map((g) => g.id), day);
});

/// True once the daily challenge game has been solved today.
final dailyChallengeDoneProvider = Provider<bool>((ref) {
  final id = ref.watch(dailyChallengeIdProvider);
  if (id == null) return false;
  return ref.watch(gameStreakNotifierProvider
      .select((streaks) => streaks[id]?.solvedToday ?? false));
});

/// Milestones just unlocked; the app shell shows a toast and clears it.
final milestoneToastProvider =
    StateProvider<List<engine.Milestone>>((ref) => const []);

/// Export / import of all player progress as a single JSON string.
class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  String export() =>
      engine.encodeBackup(_ref.read(userRepositoryProvider).exportProgress());

  /// Validates [text] first; local data is only replaced when it is valid.
  Future<void> import(String text) async {
    final data = engine.decodeBackup(text);
    await _ref.read(userRepositoryProvider).importProgress(data);
    _ref.invalidate(userDataNotifierProvider);
    _ref.invalidate(gameStreakNotifierProvider);
    _ref.invalidate(activityLogProvider);
    _ref.invalidate(gameSessionNotifierProvider);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref));
