import 'dart:math';
import 'mahjong_tile.dart';

/// Single-layer Mahjong Solitaire. Uses ED-Mahjong's matching tile rules.
/// Generates an actual removal sequence, so every new board is solvable.
class MahjongPair {
  final int first, second;
  const MahjongPair(this.first, this.second);
}
class MahjongBoard {
  final List<MahjongTile?> tiles;
  final List<MahjongPair> solutionOrder;
  final List<MahjongPair> history = [];
  final List<MahjongTile> removedFirst = [];
  final List<MahjongTile> removedSecond = [];

  MahjongBoard(this.tiles, this.solutionOrder);
  factory MahjongBoard.generate([Random? random]) {
    final rng = random ?? Random();
    final occupied = List<bool>.filled(64, true);
    final sequence = <MahjongPair>[];
    bool accessible(int index) {
      if (!occupied[index]) return false;
      final col = index % 8;
      return col == 0 || !occupied[index - 1] ||
          col == 7 || !occupied[index + 1];
    }
    while (occupied.any((x) => x)) {
      final available = [
        for (var i = 0; i < 64; i++) if (accessible(i)) i,
      ];
      if (available.length < 2) throw StateError('Invalid tile arrangement');
      final first = available.removeAt(rng.nextInt(available.length));
      final second = available[rng.nextInt(available.length)];
      sequence.add(MahjongPair(first, second));
      occupied[first] = false;
      occupied[second] = false;
    }
    // 16 distinct tile faces with four copies each: 32 removable pairs.
    final pairValues = <int>[
      for (var type = 0; type < 16; type++) ...[type, type],
    ]..shuffle(rng);
    final board = List<MahjongTile?>.filled(64, null);
    for (var i = 0; i < sequence.length; i++) {
      final face = MahjongTile.values[pairValues[i]];
      final pair = sequence[i];
      board[pair.first] = face;
      board[pair.second] = face;
    }
    return MahjongBoard(board, sequence);
  }
  int get remaining => tiles.where((x) => x != null).length;
  bool get complete => remaining == 0;
  bool isFree(int index) {
    if (index < 0 || index >= 64 || tiles[index] == null) return false;
    final col = index % 8;
    return col == 0 || tiles[index - 1] == null ||
        col == 7 || tiles[index + 1] == null;
  }
  List<MahjongPair> get matches {
    final accessible = [
      for (var i = 0; i < 64; i++) if (isFree(i)) i,
    ];
    final pairs = <MahjongPair>[];
    for (var i = 0; i < accessible.length; i++) {
      for (var j = i + 1; j < accessible.length; j++) {
        final a = accessible[i], b = accessible[j];
        if (doMatch(tiles[a]!, tiles[b]!)) pairs.add(MahjongPair(a, b));
      }
    }
    return pairs;
  }
  bool remove(int a, int b) {
    if (a == b || !isFree(a) || !isFree(b) ||
        !doMatch(tiles[a]!, tiles[b]!)) return false;
    history.add(MahjongPair(a, b));
    removedFirst.add(tiles[a]!);
    removedSecond.add(tiles[b]!);
    tiles[a] = null;
    tiles[b] = null;
    return true;
  }
  void undo() {
    if (history.isEmpty) return;
    final pair = history.removeLast();
    tiles[pair.first] = removedFirst.removeLast();
    tiles[pair.second] = removedSecond.removeLast();
  }
  static String tileGlyph(MahjongTile tile) {
    final index = tile.index;
    if (index >= 0 && index < 9) {
      return String.fromCharCode(0x1F007 + index);
    }
    if (index >= 9 && index < 18) {
      return String.fromCharCode(0x1F010 + (index - 9));
    }
    if (index >= 18 && index < 27) {
      return String.fromCharCode(0x1F019 + (index - 18));
    }
    // Fallback label for any future layout containing flowers or honors.
    return tileToString(tile).replaceAll('_', ' ');
  }
}
