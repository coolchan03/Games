import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_data.dart';
import '../models/game_streak.dart';

class UserRepository {
  static const String userDataBoxName = 'user_data';
  static const String gameStreakBoxName = 'game_streaks';
  static const String _metaBoxName = 'app_meta';
  static const String _versionKey = 'schema_version';
  static const String _recentGameIdsKey = 'recent_game_ids';
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

  Future<void> clearAll() async {
    try {
      await Hive.box<UserData>(userDataBoxName).clear();
      await Hive.box<GameStreak>(gameStreakBoxName).clear();
      if (Hive.isBoxOpen(_metaBoxName)) {
        await Hive.box(_metaBoxName).delete(_recentGameIdsKey);
      }
    } catch (e) {
      debugPrint('clearAll error: $e');
      rethrow;
    }
  }
}
