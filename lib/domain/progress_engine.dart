import 'dart:convert';
import 'dart:math' as math;

/// Pure, UI-free progress logic: levels, activity history, achievements, the
/// daily challenge and backup encoding. Everything here is deterministic so it
/// can be unit-tested without Flutter or Hive.

// ---------------------------------------------------------------------------
// Dates
// ---------------------------------------------------------------------------

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b], immune to DST (23/25-hour days).
int calendarDaysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final date = DateTime(y, mo, d);
  return date.month == mo && date.day == d ? date : null;
}

// ---------------------------------------------------------------------------
// Levels
// ---------------------------------------------------------------------------

const int maxLevel = 100;

/// XP required to *reach* [level] (level 1 needs none).
int xpForLevel(int level) {
  if (level <= 1) return 0;
  final l = math.min(level, maxLevel + 1);
  return (100 * math.pow(l - 1, 2.04)).floor();
}

/// Highest level whose threshold is <= [xp]. Always consistent with
/// [xpForLevel], so a freshly-reached level never reads as "99% of previous".
int levelForXp(int xp) {
  if (xp <= 0) return 1;
  var level = (math.pow(xp / 100, 1 / 2.04)).floor() + 1;
  level = level.clamp(1, maxLevel);
  while (level < maxLevel && xpForLevel(level + 1) <= xp) {
    level++;
  }
  while (level > 1 && xpForLevel(level) > xp) {
    level--;
  }
  return level;
}

class LevelProgress {
  final int level;
  final int xpIntoLevel;
  final int xpForNext;

  /// 0..1. Always 1 at the level cap.
  final double fraction;
  final bool isMax;
  const LevelProgress(
      this.level, this.xpIntoLevel, this.xpForNext, this.fraction, this.isMax);
}

LevelProgress levelProgress(int xp) {
  final safeXp = math.max(0, xp);
  final level = levelForXp(safeXp);
  if (level >= maxLevel) {
    return const LevelProgress(maxLevel, 0, 0, 1.0, true);
  }
  final start = xpForLevel(level);
  final span = xpForLevel(level + 1) - start;
  final into = safeXp - start;
  return LevelProgress(
      level, into, span, span <= 0 ? 1.0 : (into / span).clamp(0.0, 1.0), false);
}

// ---------------------------------------------------------------------------
// Activity log (day -> number of puzzles solved)
// ---------------------------------------------------------------------------

typedef ActivityLog = Map<String, int>;

ActivityLog recordActivity(ActivityLog log, DateTime when, {int count = 1}) {
  final key = dayKey(when);
  return {...log, key: (log[key] ?? 0) + count};
}

/// Drops malformed keys/values; keeps the newest [keepDays] days.
ActivityLog sanitizeActivity(Object? raw, {int keepDays = 400, DateTime? now}) {
  if (raw is! Map) return {};
  final today = dayOf(now ?? DateTime.now());
  final out = <String, int>{};
  raw.forEach((k, v) {
    if (k is! String || v is! int || v <= 0) return;
    final date = parseDayKey(k);
    if (date == null) return;
    if (calendarDaysBetween(date, today) > keepDays) return;
    out[k] = v;
  });
  return out;
}

/// Consecutive active days ending today — or yesterday, so a streak is not
/// shown as broken before the player has had a chance to play today.
int currentActiveStreak(ActivityLog log, DateTime now) {
  var cursor = dayOf(now);
  if ((log[dayKey(cursor)] ?? 0) == 0) {
    cursor = cursor.subtract(const Duration(days: 1));
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
  }
  var streak = 0;
  while ((log[dayKey(cursor)] ?? 0) > 0) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

int longestActiveStreak(ActivityLog log) {
  final days = log.entries
      .where((e) => e.value > 0)
      .map((e) => parseDayKey(e.key))
      .whereType<DateTime>()
      .toList()
    ..sort();
  var best = 0, run = 0;
  DateTime? prev;
  for (final d in days) {
    run = (prev != null && calendarDaysBetween(prev, d) == 1) ? run + 1 : 1;
    best = math.max(best, run);
    prev = d;
  }
  return best;
}

/// Solved counts for the [weeks] most recent weeks, oldest first, as a grid of
/// columns (weeks) x 7 rows. [weekStartsOn] uses DateTime weekdays (1 = Mon).
/// Days after today are null.
List<List<int?>> activityGrid(ActivityLog log, DateTime now,
    {int weeks = 15, int weekStartsOn = DateTime.monday}) {
  final today = dayOf(now);
  final offset = (today.weekday - weekStartsOn + 7) % 7;
  final firstDay =
      DateTime(today.year, today.month, today.day - offset - (weeks - 1) * 7);
  return List.generate(weeks, (w) {
    return List<int?>.generate(7, (d) {
      final day =
          DateTime(firstDay.year, firstDay.month, firstDay.day + w * 7 + d);
      if (day.isAfter(today)) return null;
      return log[dayKey(day)] ?? 0;
    });
  });
}

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

class ProgressSnapshot {
  final int xp;
  final int totalSolved;
  final int level;
  final int distinctGamesPlayed;
  final int categoriesPlayed;
  final int bestDayStreak;
  final int activeDays;
  final int bestSingleDay;
  const ProgressSnapshot({
    this.xp = 0,
    this.totalSolved = 0,
    this.level = 1,
    this.distinctGamesPlayed = 0,
    this.categoriesPlayed = 0,
    this.bestDayStreak = 0,
    this.activeDays = 0,
    this.bestSingleDay = 0,
  });
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final int target;
  final int Function(ProgressSnapshot) current;
  const Milestone(this.id, this.title, this.description, this.target, this.current);

  int progress(ProgressSnapshot s) => math.min(current(s), target);
  double fraction(ProgressSnapshot s) => target <= 0 ? 1 : progress(s) / target;
  bool isUnlocked(ProgressSnapshot s) => current(s) >= target;
}

/// Behaviour-based milestones that complement the XP tiers.
final List<Milestone> milestones = [
  Milestone('first_solve', 'First Steps', 'Solve your first puzzle', 1, (s) => s.totalSolved),
  Milestone('solved_25', 'Warming Up', 'Solve 25 puzzles', 25, (s) => s.totalSolved),
  Milestone('solved_100', 'Centurion', 'Solve 100 puzzles', 100, (s) => s.totalSolved),
  Milestone('solved_500', 'Relentless', 'Solve 500 puzzles', 500, (s) => s.totalSolved),
  Milestone('explorer_10', 'Explorer', 'Play 10 different games', 10, (s) => s.distinctGamesPlayed),
  Milestone('explorer_50', 'Globetrotter', 'Play 50 different games', 50, (s) => s.distinctGamesPlayed),
  Milestone('all_rounder', 'All-Rounder', 'Play games from 6 categories', 6, (s) => s.categoriesPlayed),
  Milestone('streak_3', 'On a Roll', 'Play 3 days in a row', 3, (s) => s.bestDayStreak),
  Milestone('streak_7', 'Week Warrior', 'Play 7 days in a row', 7, (s) => s.bestDayStreak),
  Milestone('streak_30', 'Unstoppable', 'Play 30 days in a row', 30, (s) => s.bestDayStreak),
  Milestone('marathon', 'Marathon', 'Solve 10 puzzles in one day', 10, (s) => s.bestSingleDay),
  Milestone('level_10', 'Rising Star', 'Reach level 10', 10, (s) => s.level),
];

/// Milestones newly unlocked when moving from [before] to [after].
List<Milestone> newlyUnlocked(ProgressSnapshot before, ProgressSnapshot after) =>
    milestones.where((m) => !m.isUnlocked(before) && m.isUnlocked(after)).toList();

// ---------------------------------------------------------------------------
// Daily challenge
// ---------------------------------------------------------------------------

const int dailyChallengeBonusXp = 30;

/// Same game for everyone on a given calendar day, independent of list order.
String? dailyChallengeGameId(Iterable<String> gameIds, DateTime day) {
  final ids = gameIds.toSet().toList()..sort();
  if (ids.isEmpty) return null;
  // FNV-1a over the day key: stable across platforms and runs.
  var hash = 0x811C9DC5;
  for (final unit in dayKey(day).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return ids[hash % ids.length];
}

// ---------------------------------------------------------------------------
// Streak reconciliation
// ---------------------------------------------------------------------------

/// Whether a per-game streak last solved on [last] is already broken on [now].
bool isStreakBroken(DateTime last, DateTime now) =>
    calendarDaysBetween(last, now) > 1;

// ---------------------------------------------------------------------------
// Backup codec
// ---------------------------------------------------------------------------

const int backupVersion = 1;
const String backupMagic = 'puzzle-master-backup';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

String encodeBackup(Map<String, dynamic> payload) => jsonEncode({
      'app': backupMagic,
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      ...payload,
    });

Map<String, dynamic> decodeBackup(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text.trim());
  } on FormatException {
    throw BackupException('That is not a valid backup.');
  }
  if (decoded is! Map<String, dynamic> || decoded['app'] != backupMagic) {
    throw BackupException('That is not a Puzzle Master backup.');
  }
  final version = decoded['version'];
  if (version is! int || version < 1 || version > backupVersion) {
    throw BackupException('This backup was made by a newer version of the app.');
  }
  return decoded;
}
