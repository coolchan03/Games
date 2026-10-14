import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/mahjong_board.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/mahjong_tile.dart';
void main() {
  test('an overlapping tile above blocks, including half-tile overlap', () {
    final face = MahjongTile.values.first;
    final board = MahjongBoard([face, face, face], [], positions: const [
      MahjongPosition(0, 0, 0), MahjongPosition(1, 1, 1), MahjongPosition(5, 0, 0)]);
    expect(board.isFree(0), false); expect(board.isFree(1), true); expect(board.isFree(2), true);
  });
  test('both side neighbours block; one open side is sufficient', () {
    final face = MahjongTile.values.first;
    final board = MahjongBoard([face, face, face], [], positions: const [
      MahjongPosition(0, 0, 0), MahjongPosition(2, 0, 0), MahjongPosition(4, 0, 0)]);
    expect(board.isFree(1), false); expect(board.isFree(0), true);
    board.tiles[0] = null; expect(board.isFree(1), true);
  });
  test('all layouts and seeded deals have a complete legal solution', () {
    for (final entry in {'flat': 64, 'terraces': 96, 'pagoda': 144}.entries) {
      for (var seed = 0; seed < 50; seed++) {
        final board = MahjongBoard.generate(Random(seed), entry.key);
        expect(board.remaining, entry.value);
        for (final pair in board.solutionOrder) {
          expect(board.remove(pair.first, pair.second), true, reason: '${entry.key}/$seed');
        }
        expect(board.complete, true);
        board.undo(); expect(board.remaining, 2);
      }
    }
  });
  test('layered save retains board, legal moves and undo history', () {
    final board = MahjongBoard.generate(Random(12), 'pagoda');
    for (final pair in board.solutionOrder.take(9)) { board.remove(pair.first, pair.second); }
    final restored = MahjongBoard.fromJson(board.toJson());
    expect(restored.tiles, board.tiles); expect(restored.history.length, 9);
    restored.undo(); board.undo(); expect(restored.tiles, board.tiles);
  });
  test('illegal saved removals are rejected', () {
    final data = MahjongBoard.generate(Random(3), 'pagoda').toJson();
    data['moves'] = [[0, 0]];
    expect(() => MahjongBoard.fromJson(data), throwsFormatException);
  });
}
