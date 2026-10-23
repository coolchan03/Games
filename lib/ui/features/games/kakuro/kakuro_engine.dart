import 'dart:math';

import 'kakuro_campaign_data.dart';

class KakuroCell {
  final int r, c;
  final bool isWhite;
  final bool isBlock;
  final bool isClue;
  final bool isGiven;
  final int? vClue;
  final int? hClue;
  final int? solution;

  const KakuroCell({
    required this.r,
    required this.c,
    this.isWhite = false,
    this.isBlock = false,
    this.isClue = false,
    this.isGiven = false,
    this.vClue,
    this.hClue,
    this.solution,
  });
}

class KakuroLevel {
  final int size;
  final int levelNumber;
  final List<List<KakuroCell>> grid;

  const KakuroLevel({
    required this.size,
    required this.grid,
    this.levelNumber = 1,
  });
}

class KakuroRun {
  final int sum;
  final List<Point<int>> positions;
  const KakuroRun(this.sum, this.positions);
}

class KakuroEngine {
  /// Retained for callers using the previous engine API. Campaign levels are
  /// deterministic; calling this method no longer re-rolls three templates.
  KakuroLevel generateLevel({int levelNumber = 1}) => campaignLevel(levelNumber);

  static KakuroLevel campaignLevel(int number) {
    final seed = KakuroCampaignData.seed(number);
    final n = seed.size;
    final starters = seed.starters.toSet();
    final grid = <List<KakuroCell>>[];
    for (var row = 0; row < n; row++) {
      final cells = <KakuroCell>[];
      for (var col = 0; col < n; col++) {
        final digit = seed.cells[row][col];
        if (digit > 0) {
          cells.add(KakuroCell(
            r: row, c: col, isWhite: true,
            isGiven: starters.contains(row * n + col), solution: digit,
          ));
        } else {
          var across = 0;
          var down = 0;
          for (var x = col + 1; x < n && seed.cells[row][x] > 0; x++) {
            across += seed.cells[row][x];
          }
          for (var y = row + 1; y < n && seed.cells[y][col] > 0; y++) {
            down += seed.cells[y][col];
          }
          cells.add(KakuroCell(
            r: row, c: col,
            isBlock: across == 0 && down == 0,
            isClue: across > 0 || down > 0,
            hClue: across > 0 ? across : null,
            vClue: down > 0 ? down : null,
          ));
        }
      }
      grid.add(cells);
    }
    return KakuroLevel(size: n, grid: grid, levelNumber: number);
  }

  static Map<Point<int>, int?> startingValues(KakuroLevel level) {
    final values = <Point<int>, int?>{};
    for (final row in level.grid) {
      for (final cell in row) {
        if (cell.isWhite) {
          values[Point(cell.c, cell.r)] = cell.isGiven ? cell.solution : null;
        }
      }
    }
    return values;
  }

  static List<KakuroRun> clueRuns(KakuroLevel level) {
    final runs = <KakuroRun>[];
    for (var r = 0; r < level.size; r++) {
      for (var c = 0; c < level.size; c++) {
        final cell = level.grid[r][c];
        if (!cell.isClue) continue;
        if (cell.hClue != null) {
          final coords = <Point<int>>[];
          for (var x = c + 1;
              x < level.size && level.grid[r][x].isWhite; x++) {
            coords.add(Point(x, r));
          }
          runs.add(KakuroRun(cell.hClue!, coords));
        }
        if (cell.vClue != null) {
          final coords = <Point<int>>[];
          for (var y = r + 1;
              y < level.size && level.grid[y][c].isWhite; y++) {
            coords.add(Point(c, y));
          }
          runs.add(KakuroRun(cell.vClue!, coords));
        }
      }
    }
    return runs;
  }

  /// Checks displayed rules, not a hidden exact-solution comparison. The
  /// authored puzzles are independently verified to have unique solutions.
  static bool checkSolved(KakuroLevel level, Map<Point<int>, int?> values) {
    final starting = startingValues(level);
    if (values.length != starting.length) return false;
    for (final key in starting.keys) {
      final value = values[key];
      if (value == null || value < 1 || value > 9) return false;
      if (starting[key] != null && starting[key] != value) return false;
    }
    for (final run in clueRuns(level)) {
      if (run.positions.length < 2 || run.positions.length > 9) return false;
      final seen = <int>{};
      var sum = 0;
      for (final pos in run.positions) {
        final digit = values[pos];
        if (digit == null || !seen.add(digit)) return false;
        sum += digit;
      }
      if (sum != run.sum) return false;
    }
    return true;
  }

  /// Uniqueness verifier used by campaign tests (stops at two solutions).
  /// Constraint pruning avoids brute-force enumeration of all assignments.
  static int countSolutions(KakuroLevel level, {int limit = 2}) {
    final runs = clueRuns(level);
    final slots = startingValues(level);
    final memberships = <Point<int>, List<int>>{};
    final used = List<int>.filled(runs.length, 0);
    final total = List<int>.filled(runs.length, 0);
    final filled = List<int>.filled(runs.length, 0);
    for (var i = 0; i < runs.length; i++) {
      for (final position in runs[i].positions) {
        (memberships[position] ??= <int>[]).add(i);
      }
    }
    if (memberships.length != slots.length) return 0;
    final assigned = <Point<int>, int>{};
    for (final entry in slots.entries) {
      final digit = entry.value;
      if (digit == null) continue;
      assigned[entry.key] = digit;
      for (final idx in memberships[entry.key]!) {
        if ((used[idx] & (1 << digit)) != 0) return 0;
        used[idx] |= 1 << digit;
        total[idx] += digit;
        filled[idx]++;
      }
    }

    bool canFill(int missing, int sum, int mask, int nextDigit) {
      if (missing == 0) return sum == 0;
      if (sum <= 0 || nextDigit > 9 || 10 - nextDigit < missing) return false;
      for (var d = nextDigit; d <= 9; d++) {
        if ((mask & (1 << d)) != 0 || d > sum) continue;
        if (canFill(missing - 1, sum - d, mask | (1 << d), d + 1)) {
          return true;
        }
      }
      return false;
    }

    List<int> options(Point<int> position) {
      final possible = <int>[];
      for (var digit = 1; digit <= 9; digit++) {
        var allowed = true;
        for (final idx in memberships[position]!) {
          if ((used[idx] & (1 << digit)) != 0) {
            allowed = false;
            break;
          }
          final unfilled = runs[idx].positions.length - filled[idx] - 1;
          final remaining = runs[idx].sum - total[idx] - digit;
          if (!canFill(unfilled, remaining, used[idx] | (1 << digit), 1)) {
            allowed = false;
            break;
          }
        }
        if (allowed) possible.add(digit);
      }
      return possible;
    }

    var solutions = 0;
    void solve() {
      if (solutions >= limit) return;
      if (assigned.length == slots.length) {
        solutions++;
        return;
      }
      Point<int>? chosen;
      List<int>? choices;
      for (final position in slots.keys) {
        if (assigned.containsKey(position)) continue;
        final possible = options(position);
        if (possible.isEmpty) return;
        if (choices == null || possible.length < choices.length) {
          chosen = position;
          choices = possible;
          if (possible.length == 1) break;
        }
      }
      if (chosen == null || choices == null) return;
      for (final digit in choices) {
        assigned[chosen] = digit;
        for (final idx in memberships[chosen]!) {
          used[idx] |= 1 << digit;
          total[idx] += digit;
          filled[idx]++;
        }
        solve();
        for (final idx in memberships[chosen]!) {
          used[idx] &= ~(1 << digit);
          total[idx] -= digit;
          filled[idx]--;
        }
        assigned.remove(chosen);
        if (solutions >= limit) return;
      }
    }
    solve();
    return solutions;
  }
}
