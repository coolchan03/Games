import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_kit.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/layered_board.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/mahjong_tile.dart';

void main() {
  test('depth-first solver finds a win and proves an empty space lost', () {
    // 0 -> 1 -> 2(goal), plus a dead branch 0 -> 5.
    final puzzle = _Chain();
    final r = solveDepthFirst(puzzle, 0);
    expect(r.status, Solvability.solvable);
    expect(r.path.last, 2);
    expect(solveDepthFirst(puzzle, 5).status, Solvability.unsolvable);
    expect(solveDepthFirst(puzzle, 0, maxNodes: 1).status, Solvability.unknown);
  });

  test('no level starts in a position the analysis calls lost', () {
    for (var l = 1; l <= MahjongLevels.specs.length; l++) {
      final board = MahjongLevels.build(l);
      expect(board.monitor.analyze(), isNot(Solvability.unsolvable), reason: 'level $l');
      expect(board.hasStackedLastPair, isFalse, reason: 'level $l');
    }
  });

  test('following the safe hint clears boards', () {
    for (final l in [1, 3, 8, 12]) {
      final board = MahjongLevels.build(l);
      var guard = 0;
      while (!board.won && guard++ < 200) {
        final hint = board.monitor.safeHint();
        expect(hint, isNotNull, reason: 'level $l with ${board.remaining} left');
        expect(board.remove(hint!.$1, hint.$2), isTrue);
      }
      expect(board.won, isTrue, reason: 'level $l');
    }
  });

  test('a last pair stacked on itself is a proven dead end', () {
    final board = MahjongLevels.build(3); // a layered layout
    // Find a slot with another slot directly above it.
    int? lower, upper;
    for (var i = 0; i < board.tiles.length && lower == null; i++) {
      for (var j = 0; j < board.tiles.length; j++) {
        final a = board.layout.slots[i], b = board.layout.slots[j];
        if (b.z == a.z + 1 && (b.x - a.x).abs() < 2 && (b.y - a.y).abs() < 2) {
          lower = i;
          upper = j;
          break;
        }
      }
    }
    expect(lower, isNotNull);
    for (var i = 0; i < board.tiles.length; i++) {
      board.tiles[i] = null;
    }
    board.tiles[lower!] = MahjongTile.CHARACTER_1;
    board.tiles[upper!] = MahjongTile.CHARACTER_1;
    expect(board.hasStackedLastPair, isTrue);
    expect(board.monitor.trapped, isTrue);
    expect(board.monitor.safeHint(), isNull);
  });
}

class _Chain extends SearchPuzzle<int> {
  @override
  String key(int s) => '$s';
  @override
  bool isGoal(int s) => s == 2;
  @override
  Iterable<int> successors(int s) => switch (s) { 0 => [5, 1], 1 => [2], _ => [] };
}
