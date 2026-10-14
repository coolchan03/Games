import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/black_box/black_box_engine.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_engine.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/sixteen/sixteen_screen.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_screen.dart';

/// Depth-first solver used to confirm Same Game boards can be cleared.
bool clearable(SameGame g, [int budget = 200000]) {
  var nodes = 0;
  final dead = <String>{};
  bool dfs() {
    if (g.cleared) return true;
    if (++nodes > budget) return false;
    final key = g.grid.join();
    if (!dead.add(key)) return false;
    final seen = <int>{};
    for (var i = 0; i < g.grid.length; i++) {
      if (g.grid[i] == 0 || seen.contains(i)) continue;
      final grp = g.group(i);
      seen.addAll(grp);
      if (grp.length < 2) continue;
      g.remove(i);
      if (dfs()) return true;
      g.undo();
    }
    return false;
  }

  return dfs();
}

void main() {
  group('Inertia', () {
    test('directions match the original encoding', () {
      expect([for (var d = 0; d < 8; d++) (dirX(d), dirY(d))],
          [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]);
    });
    test('generated levels have gems, one player and slide to stops', () {
      for (final seed in [1, 2, 3]) {
        final g = InertiaGame(w: 10, h: 10, random: Random(seed));
        expect(g.totalGems, 20);
        final moves = [for (var d = 0; d < 8; d++) if (g.canMove(d)) d];
        expect(moves, isNotEmpty);
        g.move(moves.first);
        final c = g.at(g.grid, g.px, g.py);
        final d = moves.first;
        expect(
          g.dead || c == Cell.stop || g.at(g.grid, g.px + dirX(d), g.py + dirY(d)) == Cell.wall,
          isTrue,
        );
        g.undo();
        expect(g.moves, 0);
      }
    });
  });

  group('Same Game', () {
    test('scoring and gravity', () {
      final g = SameGame(w: 3, h: 3, solvable: false, random: Random(1));
      g.grid = [0, 0, 0, 1, 2, 0, 1, 2, 2];
      expect(g.remove(3), isTrue);
      // Column 0 empties and the other columns close up to the left.
      expect(g.grid, [0, 0, 0, 2, 0, 0, 2, 2, 0]);
      expect(SameGame.points(5), 9);
    });
    test('solvable boards can be cleared', () {
      for (final seed in [1, 2, 3, 4]) {
        final g = SameGame(w: 6, h: 6, colours: 3, random: Random(seed));
        expect(g.grid.every((c) => c > 0), isTrue);
        expect(clearable(g), isTrue, reason: 'seed $seed');
      }
    });
  });

  group('Black Box', () {
    test('lasers: hit, deflection, reflection and straight paths', () {
      final g = BlackBoxGame(n: 8, balls: 0, random: Random(1));
      // Empty box: straight through from top column 3 to bottom.
      expect(g.trace(3).kind, 'X');
      expect(g.trace(3).exit, 2 * 8 + (8 - 1 - 3));
      g.hidden.add(4 * 8 + 3); // ball at (3, 4)
      expect(g.trace(3).kind, 'H');
      g.hidden
        ..clear()
        ..add(3 * 8 + 4); // ball at (4, 3): diagonally ahead-left of column 3
      final r = g.trace(3);
      expect(r.kind, 'X');
      // Deflected away from the ball, out of the left side at row 2.
      expect(r.exit, 3 * 8 + (8 - 1 - 2));
      g.hidden
        ..clear()
        ..add(0 * 8 + 4); // ball beside the entry square at the edge
      expect(g.trace(3).kind, 'R');
    });
    test('scoring', () {
      final g = BlackBoxGame(balls: 3, random: Random(5));
      g.fire(0);
      g.fire(9);
      for (final c in g.hidden) {
        g.toggleGuess(c);
      }
      expect(g.correct, isTrue);
      expect(g.score, g.lasersUsed);
    });
  });

  group('Twiddle and Sixteen', () {
    test('rotation is undone by its inverse', () {
      final g = TwiddleGame(n: 4, block: 3, random: Random(1));
      final before = List.of(g.tiles);
      g.rotate(1, 0, true);
      g.rotate(1, 0, false);
      expect(g.tiles, before);
      g.rotate(0, 1, true);
      g.rotate(0, 1, true);
      g.rotate(0, 1, true);
      g.rotate(0, 1, true);
      expect(g.tiles, before);
    });
    test('sixteen shifts are cyclic', () {
      final g = SixteenGame(n: 4, random: Random(2));
      final before = List.of(g.tiles);
      for (var i = 0; i < 4; i++) {
        g.shiftRow(2, 1);
      }
      expect(g.tiles, before);
      g.shiftCol(1, 1);
      g.shiftCol(1, -1);
      expect(g.tiles, before);
    });
  });

  group('Signpost', () {
    test('puzzles are unique and the solution follows the arrows', () {
      for (final size in [4, 5, 6]) {
        final p = SignpostPuzzle(w: size, h: size, random: Random(size));
        expect(p.countSolutions(limit: 2), 1);
        for (var k = 0; k + 1 < p.n; k++) {
          expect(p.ray(p.solution[k], p.arrows[p.solution[k]]), contains(p.solution[k + 1]));
        }
        final g = SignpostGame(p);
        for (var k = 0; k + 1 < p.n; k++) {
          g.link(p.solution[k], p.solution[k + 1]);
        }
        expect(g.solved, isTrue);
      }
    });
  });
}
