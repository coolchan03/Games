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

  static Future<void> save(String gameId, Set<int> completed) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      final sorted = completed.where((n) => n >= 1).toList()..sort();
      await Hive.box(boxName).put('$keyPrefix$gameId', sorted);
    } catch (_) {
      // Failed optional progress writes must not prevent puzzle completion.
    }
  }
}
