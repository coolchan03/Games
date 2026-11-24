import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_kit.dart';
import 'package:puzzle/ui/features/games/water_sort/water_sort_levels.dart';

void main() {
  test('all 30 levels are well-formed, distinct and not pre-solved', () {
    final seen = <String>{};
    for (var l = 1; l <= WaterSortLevels.count; l++) {
      final level = WaterSortLevels.build(l);
      expect(level.colors, WaterSortLevels.colorsFor(l));
      expect(WaterSortLevels.isSolved(level.tubes), isFalse, reason: 'level $l');
      final all = [for (final t in level.tubes) ...t]..sort();
      expect(all.length, level.colors * WaterSortLevels.capacity);
      for (var c = 0; c < level.colors; c++) {
        expect(all.where((x) => x == c).length, WaterSortLevels.capacity);
      }
      expect(level.tubes.every((t) => t.length <= WaterSortLevels.capacity), isTrue);
      expect(seen.add(WaterSortPuzzle().key(level.tubes)), isTrue, reason: 'level $l repeats');
      // Deterministic.
      expect(WaterSortPuzzle().key(WaterSortLevels.build(l).tubes),
          WaterSortPuzzle().key(level.tubes));
    }
  });

  test('every small level is proven solvable by the solver, within par', () {
    for (var l = 1; l <= WaterSortLevels.count; l++) {
      final level = WaterSortLevels.build(l);
      if (level.colors > 4) continue;
      final r = solvePuzzle(WaterSortPuzzle(), level.tubes, maxNodes: 400000);
      expect(r.status, Solvability.solvable, reason: 'level $l');
      expect(r.moves!, lessThanOrEqualTo(level.par));
    }
  });

  test('random levels (many seeds) are always solvable', () {
    final random = Random(7);
    for (var i = 0; i < 40; i++) {
      final level = WaterSortLevels.random(1 + random.nextInt(8), random);
      final r = solvePuzzle(WaterSortPuzzle(), level.tubes, maxNodes: 400000);
      expect(r.status, Solvability.solvable, reason: 'seed ${level.seed}');
    }
  });

  test('a plain shuffle can be unsolvable - and the monitor proves it', () {
    // Two colours, capacity 4, one empty tube is enough to build a dead end:
    // both full tubes alternate colours and nothing can be poured.
    final trapped = <List<int>>[
      [0, 1, 0, 1],
      [1, 0, 1, 0],
    ];
    final monitor = TrapMonitor<Tubes>(WaterSortPuzzle());
    expect(monitor.isTrapped(trapped), isTrue);
    expect(monitor.hint(trapped), isNull);

    final fine = <List<int>>[
      [0, 1, 0, 1],
      [1, 0, 1, 0],
      <int>[],
    ];
    expect(monitor.isTrapped(fine), isFalse);
    expect(monitor.hint(fine), isNotNull);
  });

  test('save / restore round trip and rejection of foreign data', () {
    final level = WaterSortLevels.build(3);
    final data = WaterSortLevels.encode(level.tubes, 5);
    final restored = WaterSortLevels.decode(data, level)!;
    expect(restored.$2, 5);
    expect(WaterSortPuzzle().key(restored.$1), WaterSortPuzzle().key(level.tubes));
    expect(WaterSortLevels.decode([0, 1, 9], level), isNull);
    expect(WaterSortLevels.decode(data, WaterSortLevels.build(20)), isNull);
  });
}
