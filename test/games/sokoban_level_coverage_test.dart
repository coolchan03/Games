import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_engine.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_screen.dart';

Set<int> walkable(SokobanLevel level, Set<int> boxes, int player) {
  final offsets = [-level.w, 1, level.w, -1];
  final seen = <int>{player};
  final queue = <int>[player];
  for (var i = 0; i < queue.length; i++) {
    for (final delta in offsets) {
      final next = queue[i] + delta;
      if (!level.walls.contains(next) &&
          !boxes.contains(next) && seen.add(next)) {
        queue.add(next);
      }
    }
  }
  return seen;
}

/// BFS on legal box pushes, treating walking around crates as free.
bool canSolve(SokobanLevel level, {int maxStates = 30000}) {
  final offsets = [-level.w, 1, level.w, -1];
  final target = level.goals;
  final start = (boxes: Set<int>.of(level.boxes), player: level.player);
  final queue = Queue<({Set<int> boxes, int player})>()..add(start);
  final visited = <String>{};
  var examined = 0;
  while (queue.isNotEmpty) {
    final frame = queue.removeFirst();
    if (frame.boxes.length == target.length &&
        frame.boxes.containsAll(target)) return true;
    final reach = walkable(level, frame.boxes, frame.player);
    final sorted = frame.boxes.toList()..sort();
    final key = '${sorted.join(',')}/${reach.reduce((a, b) => a < b ? a : b)}';
    if (!visited.add(key)) continue;
    if (++examined > maxStates) return false;
    for (final box in frame.boxes) {
      for (final delta in offsets) {
        final stand = box - delta;
        final destination = box + delta;
        if (!reach.contains(stand) ||
            level.walls.contains(destination) ||
            frame.boxes.contains(destination)) continue;
        final pushed = Set<int>.of(frame.boxes)
          ..remove(box)
          ..add(destination);
        queue.add((boxes: pushed, player: box));
      }
    }
  }
  return false;
}

void main() {
  test('Sokoban has twenty distinct structurally valid puzzles per difficulty',
      () {
    for (final (difficulty, size, boxes) in
        [(0, 6, 2), (1, 7, 3), (2, 8, 4)]) {
      final fingerprints = <String>{};
      for (var level = 1; level <= 20; level++) {
        final seed = level * 31 + difficulty;
        final game = SokobanLevel.generate(
          seed, size: size, boxCount: boxes,
        );
        expect(game.w, size + 2);
        expect(game.h, size + 2);
        expect(game.boxes.length, boxes);
        expect(game.goals.length, boxes);
        expect(game.walls.contains(game.player), false);
        expect(game.boxes.contains(game.player), false);
        expect(game.boxes.difference(game.goals), isNotEmpty,
            reason: 'Level $level starts solved');
        for (final b in game.boxes) {
          expect(game.walls.contains(b), false);
        }
        final walls = game.walls.toList()..sort();
        final cratePos = game.boxes.toList()..sort();
        final goals = game.goals.toList()..sort();
        final fingerprint = '$walls/$cratePos/$goals';
        expect(fingerprints.add(fingerprint), true,
            reason: 'Difficulty $difficulty, level $level duplicates a map');
        if (difficulty == 0) {
          expect(canSolve(game), true,
              reason: 'Easy level $level is unreachable with legal pushes');
        }
      }
      expect(fingerprints.length, 20);
    }
  });

  testWidgets('Sokoban level selection is available on a phone-sized display',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SokobanScreen()));
    expect(find.byKey(const ValueKey('sokoban_level_selector')),
        findsOneWidget);
    expect(find.textContaining('Level 1'), findsWidgets);
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pump();
    expect(find.textContaining('Level 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
