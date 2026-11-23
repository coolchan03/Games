import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/progress_engine.dart';
import '../models/user_data.dart';
import '../models/game_streak.dart';

class UserRepository {
  static const String userDataBoxName = 'user_data';
  static const String gameStreakBoxName = 'game_streaks';
  static const String _metaBoxName = 'app_meta';
  static const String _versionKey = 'schema_version';
  static const String _recentGameIdsKey = 'recent_game_ids';
  static const String _activityKey = 'activity_log_v1';
  static const String _dailyClaimKey = 'daily_challenge_claim_v1';
  static const List<String> _campaignPrefixes = [
    'completed_campaign_levels_v1_',
    'selected_campaign_level_v1_',
    'active_campaign_state_v1_',
  ];
  static const int _currentSchemaVersion = 1;

  Future<void> init() async {
    try {
      final userBox = await Hive.openBox<UserData>(userDataBoxName);
      final streakBox = await Hive.openBox<GameStreak>(gameStreakBoxName);
      final metaBox = await Hive.openBox(_metaBoxName);

      await userBox.compact();
      await streakBox.compact();

      final version = metaBox.get(_versionKey, defaultValue: 0) as int;
      if (version < _currentSchemaVersion) {
        _validateExistingData(userBox, streakBox);
        await metaBox.put(_versionKey, _currentSchemaVersion);
      }
    } catch (e) {
      debugPrint('UserRepository init error: $e');
      rethrow;
    }
  }

  void _validateExistingData(Box<UserData> userBox, Box<GameStreak> streakBox) {
    final userData = userBox.get('current');
    if (userData != null && !userData.isValid) {
      userBox.put('current', userData.sanitized());
    }

    for (final streak in streakBox.values) {
      if (!streak.isValid) {
        streakBox.put(streak.gameId, streak.sanitized());
      }
    }
  }

  UserData getUserData() {
    try {
      final box = Hive.box<UserData>(userDataBoxName);
      final data = box.get('current', defaultValue: UserData.initial())!;
      return data.isValid ? data : data.sanitized();
    } catch (e) {
      debugPrint('getUserData error: $e');
      return UserData.initial();
    }
  }

  Future<void> saveUserData(UserData data) async {
    try {
      final box = Hive.box<UserData>(userDataBoxName);
      await box.put('current', data.isValid ? data : data.sanitized());
    } catch (e) {
      debugPrint('saveUserData error: $e');
      rethrow;
    }
  }

  List<GameStreak> getAllGameStreaks() {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      return box.values.where((s) => s.isValid).toList();
    } catch (e) {
      debugPrint('getAllGameStreaks error: $e');
      return [];
    }
  }

  GameStreak getGameStreak(String gameId) {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      final streak = box.get(gameId, defaultValue: GameStreak.initial(gameId))!;
      return streak.isValid ? streak : streak.sanitized();
    } catch (e) {
      debugPrint('getGameStreak error: $e');
      return GameStreak.initial(gameId);
    }
  }

  Future<void> saveGameStreak(GameStreak streak) async {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      await box.put(streak.gameId, streak.isValid ? streak : streak.sanitized());
    } catch (e) {
      debugPrint('saveGameStreak error: $e');
      rethrow;
    }
  }

  Future<void> saveAllGameStreaks(List<GameStreak> streaks) async {
    try {
      final box = Hive.box<GameStreak>(gameStreakBoxName);
      final validStreaks = streaks.where((s) => s.isValid);
      final streakMap = {for (var s in validStreaks) s.gameId: s};
      await box.putAll(streakMap);
    } catch (e) {
      debugPrint('saveAllGameStreaks error: $e');
      rethrow;
    }
  }

  Future<void> saveGameCompletion(UserData userData, GameStreak streak) async {
    try {
      final userBox = Hive.box<UserData>(userDataBoxName);
      final streakBox = Hive.box<GameStreak>(gameStreakBoxName);
      await Future.wait([
        userBox.put('current', userData.isValid ? userData : userData.sanitized()),
        streakBox.put(streak.gameId, streak.isValid ? streak : streak.sanitized()),
      ]);
    } catch (e) {
      debugPrint('saveGameCompletion error: $e');
      rethrow;
    }
  }

  /// Most recently launched games, stored offline without a new Hive adapter.
  List<String> getRecentGameIds() {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return const <String>[];
      final value = Hive.box(_metaBoxName).get(_recentGameIdsKey);
      if (value is! List) return const <String>[];
      return value.whereType<String>().where((id) => id.isNotEmpty)
          .take(20).toList();
    } catch (e) {
      debugPrint('getRecentGameIds error: $e');
      return const <String>[];
    }
  }

  Future<void> saveRecentGameIds(List<String> gameIds) async {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return;
      await Hive.box(_metaBoxName).put(
          _recentGameIdsKey, gameIds.take(20).toList());
    } catch (e) {
      // Recent history is optional: never prevent a game from launching.
      debugPrint('saveRecentGameIds error: $e');
    }
  }


  // --- Activity history & daily challenge -----------------------------------

  ActivityLog getActivityLog() {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return {};
      final raw = Hive.box(_metaBoxName).get(_activityKey);
      return sanitizeActivity(raw is Map ? Map<dynamic, dynamic>.from(raw) : null);
    } catch (e) {
      debugPrint('getActivityLog error: $e');
      return {};
    }
  }

  Future<void> saveActivityLog(ActivityLog log) async {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return;
      await Hive.box(_metaBoxName).put(_activityKey, Map<String, int>.from(log));
    } catch (e) {
      // History is a nicety: never block a completion on it.
      debugPrint('saveActivityLog error: $e');
    }
  }

  /// Day key of the last claimed daily-challenge bonus, if any.
  String? getDailyClaim() {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return null;
      final v = Hive.box(_metaBoxName).get(_dailyClaimKey);
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyClaim(String key) async {
    try {
      if (!Hive.isBoxOpen(_metaBoxName)) return;
      await Hive.box(_metaBoxName).put(_dailyClaimKey, key);
    } catch (e) {
      debugPrint('saveDailyClaim error: $e');
    }
  }

  // --- Backup / restore -------------------------------------------------------

  /// JSON-safe snapshot of everything that represents player progress.
  Map<String, dynamic> exportProgress() {
    final user = getUserData();
    final meta = Hive.isBoxOpen(_metaBoxName) ? Hive.box(_metaBoxName) : null;
    final campaign = <String, List<int>>{};
    if (meta != null) {
      for (final key in meta.keys) {
        if (key is! String || !_campaignPrefixes.any(key.startsWith)) continue;
        final value = meta.get(key);
        if (value is List && value.every((v) => v is int)) {
          campaign[key] = List<int>.from(value);
        } else if (value is int) {
          campaign[key] = [value];
        }
      }
    }
    return {
      'user': {
        'xp': user.xp,
        'level': user.level,
        'superStreak': user.superStreak ?? 0,
        'lastSuperStreakDate': user.lastSuperStreakDate?.toIso8601String(),
        'totalSolved': user.totalSolved ?? 0,
        'favoriteGameIds': user.favoriteGameIds ?? const <String>[],
        'hiddenGameIds': user.hiddenGameIds ?? const <String>[],
        'isTrialModeEnabled': user.isTrialModeEnabled ?? false,
        'isKeepScreenAwakeEnabled': user.isKeepScreenAwakeEnabled ?? false,
      },
      'streaks': [
        for (final s in getAllGameStreaks())
          {
            'gameId': s.gameId,
            'currentStreak': s.currentStreak,
            'lastSolvedDate': s.lastSolvedDate.toIso8601String(),
            'solvedToday': s.solvedToday,
          }
      ],
      'activity': getActivityLog(),
      'recent': getRecentGameIds(),
      'campaign': campaign,
    };
  }

  /// Replaces local progress with a decoded backup. Throws [BackupException]
  /// without touching local data when the payload is malformed.
  Future<void> importProgress(Map<String, dynamic> data) async {
    final user = data['user'];
    if (user is! Map) throw BackupException('Backup has no player data.');
    int nonNeg(Object? v) => v is int && v > 0 ? v : 0;
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toSet().toList() : <String>[];
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;

    final xp = nonNeg(user['xp']);
    final restoredUser = UserData(
      xp: xp,
      level: levelForXp(xp),
      superStreak: nonNeg(user['superStreak']),
      lastSuperStreakDate: date(user['lastSuperStreakDate']),
      totalSolved: nonNeg(user['totalSolved']),
      favoriteGameIds: strings(user['favoriteGameIds']),
      hiddenGameIds: strings(user['hiddenGameIds']),
      isTrialModeEnabled: user['isTrialModeEnabled'] == true,
      isKeepScreenAwakeEnabled: user['isKeepScreenAwakeEnabled'] == true,
    );

    final streaks = <GameStreak>[];
    final rawStreaks = data['streaks'];
    if (rawStreaks is List) {
      for (final s in rawStreaks) {
        if (s is! Map || s['gameId'] is! String) continue;
        final last = date(s['lastSolvedDate']);
        if (last == null) continue;
        final streak = GameStreak(
          gameId: s['gameId'] as String,
          currentStreak: nonNeg(s['currentStreak']),
          lastSolvedDate: last,
          solvedToday: s['solvedToday'] == true,
        );
        if (streak.isValid) streaks.add(streak);
      }
    }

    await clearAll();
    await saveUserData(restoredUser);
    await saveAllGameStreaks(streaks);
    await saveActivityLog(sanitizeActivity(data['activity']));
    await saveRecentGameIds(strings(data['recent']));
    final campaign = data['campaign'];
    if (campaign is Map && Hive.isBoxOpen(_metaBoxName)) {
      final meta = Hive.box(_metaBoxName);
      for (final e in campaign.entries) {
        final key = e.key;
        final value = e.value;
        if (key is! String || !_campaignPrefixes.any(key.startsWith)) continue;
        if (value is! List || !value.every((v) => v is int)) continue;
        await meta.put(key, List<int>.from(value));
      }
    }
  }

  Future<void> clearAll() async {
    try {
      await Hive.box<UserData>(userDataBoxName).clear();
      await Hive.box<GameStreak>(gameStreakBoxName).clear();
      if (Hive.isBoxOpen(_metaBoxName)) {
        final metaBox = Hive.box(_metaBoxName);
        await metaBox.delete(_recentGameIdsKey);
        await metaBox.delete(_activityKey);
        await metaBox.delete(_dailyClaimKey);
        final campaignKeys = metaBox.keys.where((key) => key is String &&
            _campaignPrefixes.any(key.startsWith)).toList();
        await metaBox.deleteAll(campaignKeys);
      }
    } catch (e) {
      debugPrint('clearAll error: $e');
      rethrow;
    }
  }
}
