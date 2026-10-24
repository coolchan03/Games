import 'package:hive/hive.dart';

/// Small, offline-only completion ledger for numbered puzzle campaigns.
///
/// Stored as primitive integers in the already-open app_meta Hive box, so
/// there is no new adapter, dependency, account, or networking requirement.
class CampaignProgress {
  static const boxName = 'app_meta';
  static const keyPrefix = 'completed_campaign_levels_v1_';

  static Set<int> load(String gameId, {int? maxLevel}) {
    try {
      if (!Hive.isBoxOpen(boxName)) return <int>{};
      final raw = Hive.box(boxName).get('$keyPrefix$gameId');
      if (raw is! List) return <int>{};
      return raw.whereType<int>().where(
        (n) => n >= 1 && (maxLevel == null || n <= maxLevel),
      ).toSet();
    } catch (_) {
      return <int>{};
    }
  }

  static int selectedLevel(String gameId, {required int count}) {
    try {
      if (!Hive.isBoxOpen(boxName)) return 1;
      final value = Hive.box(boxName).get('selected_campaign_level_v1_$gameId');
      if (value is int && value >= 1 && value <= count) return value;
    } catch (_) {
      // Continue at the beginning when offline storage is unavailable.
    }
    return 1;
  }

  static Future<void> saveSelected(String gameId, int level) async {
    if (level < 1) return;
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      await Hive.box(boxName)
          .put('selected_campaign_level_v1_$gameId', level);
    } catch (_) {
      // An optional progress write must not prevent a level change.
    }
  }

  static String _activeKey(String gameId, int level) =>
      'active_campaign_state_v1_${gameId}_$level';

  /// Returns a detached copy; never trust stored values without validating
  /// them against the current, regenerated level.
  static List<int>? loadActive(String gameId, int level,
      {required int maxLength}) {
    try {
      if (!Hive.isBoxOpen(boxName)) return null;
      final raw = Hive.box(boxName).get(_activeKey(gameId, level));
      if (raw is! List || raw.isEmpty || raw.length > maxLength ||
          raw.any((v) => v is! int)) return null;
      return List<int>.from(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActive(String gameId, int level,
      List<int> payload) async {
    try {
      if (!Hive.isBoxOpen(boxName) || level < 1) return;
      await Hive.box(boxName).put(_activeKey(gameId, level),
          List<int>.from(payload));
    } catch (_) {
      // Progress persistence is best-effort while offline.
    }
  }

  static Future<void> clearActive(String gameId, int level) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      await Hive.box(boxName).delete(_activeKey(gameId, level));
    } catch (_) {
      // A failed optional cleanup cannot block a new puzzle.
    }
  }

  static Future<void> save(String gameId, Set<int> completed) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      final sorted = completed.where((n) => n >= 1).toList()..sort();
      await Hive.box(boxName).put('$keyPrefix$gameId', sorted);
    } catch (_) {
      // Failed optional progress writes must not prevent puzzle completion.
    }
  }

  static String _resultsKey(String gameId) => 'campaign_results_v1_$gameId';

  /// Best result per level: level -> (stars 1-3, best score).
  static Map<int, (int, int)> loadResults(String gameId) {
    try {
      if (!Hive.isBoxOpen(boxName)) return {};
      final raw = Hive.box(boxName).get(_resultsKey(gameId));
      if (raw is! List) return {};
      final values = raw.whereType<int>().toList();
      return {
        for (var i = 0; i + 2 < values.length; i += 3)
          if (values[i] >= 1 && values[i + 1] >= 1 && values[i + 1] <= 3)
            values[i]: (values[i + 1], values[i + 2]),
      };
    } catch (_) {
      return {};
    }
  }

  /// Keeps the better of the stored and new result for [level] (more stars
  /// first, then the better score). Returns the merged map.
  static Map<int, (int, int)> recordResult(String gameId, int level,
      {required int stars, required int score, bool lowerIsBetter = true}) {
    final results = loadResults(gameId);
    final old = results[level];
    final s = stars.clamp(1, 3);
    final best = old == null
        ? score
        : lowerIsBetter
            ? (score < old.$2 ? score : old.$2)
            : (score > old.$2 ? score : old.$2);
    results[level] = (old == null || s > old.$1 ? s : old.$1, best);
    try {
      if (Hive.isBoxOpen(boxName)) {
        final levels = results.keys.toList()..sort();
        unawaitedPut(_resultsKey(gameId), [
          for (final l in levels) ...[l, results[l]!.$1, results[l]!.$2],
        ]);
      }
    } catch (_) {
      // Best scores are optional; never block finishing a level.
    }
    return results;
  }

  static void unawaitedPut(String key, Object value) {
    Hive.box(boxName).put(key, value).catchError((Object _) {});
  }
}

