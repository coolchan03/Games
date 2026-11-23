import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/domain/progress_engine.dart';

void main() {
  group('levels', () {
    test('threshold and level are consistent for every level', () {
      for (var l = 1; l <= maxLevel; l++) {
        expect(levelForXp(xpForLevel(l)), l, reason: 'level $l');
        if (l > 1) expect(levelForXp(xpForLevel(l) - 1), l - 1);
      }
    });
    test('progress is bounded and maxes out', () {
      expect(levelProgress(0).fraction, 0);
      expect(levelProgress(-50).level, 1);
      final p = levelProgress(xpForLevel(5) + 1);
      expect(p.level, 5);
      expect(p.fraction, inInclusiveRange(0, 1));
      final max = levelProgress(xpForLevel(100) * 3);
      expect(max.isMax, isTrue);
      expect(max.fraction, 1);
    });
  });

  group('dates', () {
    test('calendarDaysBetween ignores DST', () {
      expect(calendarDaysBetween(DateTime(2026, 3, 7), DateTime(2026, 3, 9)), 2);
      expect(calendarDaysBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 1);
    });
    test('day keys round-trip and reject garbage', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(parseDayKey('2026-01-05'), DateTime(2026, 1, 5));
      expect(parseDayKey('2026-02-30'), isNull);
      expect(parseDayKey('nope'), isNull);
    });
  });

  group('activity', () {
    final now = DateTime(2026, 11, 23, 15);
    test('streak counts through yesterday', () {
      final log = {'2026-11-22': 2, '2026-11-21': 1, '2026-11-19': 4};
      expect(currentActiveStreak(log, now), 2);
      expect(currentActiveStreak({...log, '2026-11-23': 1}, now), 3);
      expect(currentActiveStreak({'2026-11-20': 1}, now), 0);
      expect(longestActiveStreak(log), 2);
      expect(longestActiveStreak({}), 0);
    });
    test('grid is weeks x 7 and hides the future', () {
      final grid = activityGrid({'2026-11-23': 3}, now, weeks: 4);
      expect(grid.length, 4);
      expect(grid.every((w) => w.length == 7), isTrue);
      expect(grid.last[0], 3); // Monday 23 Nov
      expect(grid.last[1], isNull); // tomorrow
    });
    test('sanitize drops bad entries', () {
      final clean = sanitizeActivity(
          {'2026-11-22': 2, 'bad': 1, '2026-11-21': -1, '2020-01-01': 5, 7: 1},
          now: now);
      expect(clean, {'2026-11-22': 2});
      expect(sanitizeActivity('x'), isEmpty);
    });
    test('recordActivity is non-mutating', () {
      final a = <String, int>{};
      final b = recordActivity(a, now);
      expect(a, isEmpty);
      expect(b['2026-11-23'], 1);
    });
  });

  group('milestones', () {
    test('unlock transitions are reported once', () {
      const before = ProgressSnapshot(totalSolved: 0);
      const after = ProgressSnapshot(totalSolved: 1, distinctGamesPlayed: 1);
      expect(newlyUnlocked(before, after).map((m) => m.id), ['first_solve']);
      expect(newlyUnlocked(after, after), isEmpty);
    });
    test('ids are unique', () {
      expect(milestones.map((m) => m.id).toSet().length, milestones.length);
    });
  });

  group('daily challenge', () {
    test('is stable, order independent and varies by day', () {
      final ids = ['b', 'a', 'c', 'd', 'e'];
      final day = DateTime(2026, 11, 23);
      expect(dailyChallengeGameId(ids, day), dailyChallengeGameId(ids.reversed, day));
      final picks = {
        for (var i = 0; i < 20; i++) dailyChallengeGameId(ids, day.add(Duration(days: i)))
      };
      expect(picks.length, greaterThan(1));
      expect(dailyChallengeGameId(const [], day), isNull);
    });
  });

  group('backup', () {
    test('round trip and validation', () {
      final text = encodeBackup({'xp': 5});
      expect(decodeBackup(text)['xp'], 5);
      expect(() => decodeBackup('{'), throwsA(isA<BackupException>()));
      expect(() => decodeBackup('{"app":"other"}'), throwsA(isA<BackupException>()));
      expect(() => decodeBackup('{"app":"$backupMagic","version":99}'),
          throwsA(isA<BackupException>()));
    });
  });

  test('streak breaks after a missed day', () {
    expect(isStreakBroken(DateTime(2026, 11, 21), DateTime(2026, 11, 23)), isTrue);
    expect(isStreakBroken(DateTime(2026, 11, 22), DateTime(2026, 11, 23)), isFalse);
  });
}
