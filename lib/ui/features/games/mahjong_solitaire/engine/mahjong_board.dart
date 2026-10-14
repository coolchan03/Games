import 'dart:math';
import 'mahjong_tile.dart';

class MahjongPair {
  final int first, second;
  const MahjongPair(this.first, this.second);
}
class MahjongPosition {
  final int x, y, z;
  const MahjongPosition(this.x, this.y, this.z);
}

/// Half-tile coordinates and overlap/free-side rules adapted from ED-Mahjong's
/// MIT layout_precalc.dart, commit c74ba1ea9106b53564e1e3e2adb58e13bbebba1b.
/// No upstream artwork is used. Layouts and solvable deal generation are original.
class MahjongBoard {
  final List<MahjongTile?> tiles;
  final List<MahjongTile?> initialTiles;
  final List<MahjongPair> solutionOrder;
  final List<MahjongPosition> positions;
  final String layoutId;
  final List<MahjongPair> history = [];
  final List<MahjongTile> removedFirst = [], removedSecond = [];
  MahjongBoard(this.tiles, this.solutionOrder, {List<MahjongPosition>? positions,
      this.layoutId = 'flat'})
      : initialTiles = List<MahjongTile?>.from(tiles),
        positions = positions ?? layout('flat') {
    if (this.positions.length != tiles.length) throw ArgumentError('Layout size mismatch');
  }
  static const layoutNames = {'flat': 'Garden - 64', 'terraces': 'Terraces - 96', 'pagoda': 'Pagoda - 144'};
  static List<MahjongPosition> layout(String id) {
    final result = <MahjongPosition>[];
    void rectangle(int columns, int rows, int x, int y, int z) {
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < columns; c++) { result.add(MahjongPosition(x + c * 2, y + r * 2, z)); }
      }
    }
    switch (id) {
      case 'flat': rectangle(8, 8, 0, 0, 0);
      case 'terraces':
        rectangle(10, 6, 0, 0, 0); rectangle(6, 4, 4, 2, 1);
        rectangle(4, 2, 6, 4, 2); rectangle(2, 2, 8, 4, 3);
      case 'pagoda':
        for (var r = 0; r < 8; r++) { rectangle(r == 0 || r == 7 ? 8 : 12, 1, r == 0 || r == 7 ? 4 : 0, r * 2, 0); }
        rectangle(6, 6, 6, 2, 1); rectangle(4, 4, 8, 4, 2); rectangle(2, 2, 10, 6, 3);
      default: throw ArgumentError.value(id, 'layout');
    }
    return result;
  }
  factory MahjongBoard.generate([Random? random, String layoutId = 'flat']) {
    final rng = random ?? Random();
    final positions = layout(layoutId);
    final remaining = {for (var i = 0; i < positions.length; i++) i};
    final order = <MahjongPair>[];
    // Clear topmost rows from both ends. Every pair is geometrically free.
    while (remaining.isNotEmpty) {
      final z = remaining.map((i) => positions[i].z).reduce(max);
      final rows = remaining.where((i) => positions[i].z == z).map((i) => positions[i].y).toSet().toList()..shuffle(rng);
      final row = remaining.where((i) => positions[i].z == z && positions[i].y == rows.first).toList()
        ..sort((a, b) => positions[a].x.compareTo(positions[b].x));
      final pair = MahjongPair(row.first, row.last);
      if (pair.first == pair.second) throw StateError('Layout rows must contain pairs');
      order.add(pair); remaining.remove(pair.first); remaining.remove(pair.second);
    }
    final faces = <List<MahjongTile>>[
      for (var i = 0; i < 27; i++) for (var n = 0; n < 2; n++) [MahjongTile.values[i], MahjongTile.values[i]],
      for (var i = 35; i < 42; i++) for (var n = 0; n < 2; n++) [MahjongTile.values[i], MahjongTile.values[i]],
      for (var i = 27; i < 35; i += 2) [MahjongTile.values[i], MahjongTile.values[i + 1]],
    ]..shuffle(rng);
    final tiles = List<MahjongTile?>.filled(positions.length, null);
    for (var i = 0; i < order.length; i++) {
      faces[i].shuffle(rng);
      tiles[order[i].first] = faces[i][0]; tiles[order[i].second] = faces[i][1];
    }
    return MahjongBoard(tiles, order, positions: positions, layoutId: layoutId);
  }
  int get remaining => tiles.where((tile) => tile != null).length;
  bool get complete => remaining == 0;
  bool isFree(int index) {
    if (index < 0 || index >= tiles.length || tiles[index] == null) return false;
    final p = positions[index];
    var left = false, right = false;
    for (var i = 0; i < positions.length; i++) {
      if (i == index || tiles[i] == null) continue;
      final q = positions[i];
      if (q.z > p.z && (q.x - p.x).abs() < 2 && (q.y - p.y).abs() < 2) return false;
      if (q.z == p.z && (q.y - p.y).abs() < 2) {
        if (q.x == p.x - 2) left = true;
        if (q.x == p.x + 2) right = true;
      }
    }
    return !left || !right;
  }
  List<MahjongPair> get matches {
    final free = [for (var i = 0; i < tiles.length; i++) if (isFree(i)) i];
    return [for (var a = 0; a < free.length; a++) for (var b = a + 1; b < free.length; b++)
      if (doMatch(tiles[free[a]]!, tiles[free[b]]!)) MahjongPair(free[a], free[b])];
  }
  bool remove(int first, int second) {
    if (first == second || !isFree(first) || !isFree(second) || !doMatch(tiles[first]!, tiles[second]!)) return false;
    history.add(MahjongPair(first, second));
    removedFirst.add(tiles[first]!); removedSecond.add(tiles[second]!);
    tiles[first] = null; tiles[second] = null;
    return true;
  }
  void undo() {
    if (history.isEmpty) return;
    final pair = history.removeLast();
    tiles[pair.first] = removedFirst.removeLast(); tiles[pair.second] = removedSecond.removeLast();
  }
  MahjongBoard restart() => MahjongBoard(List<MahjongTile?>.from(initialTiles),
    List<MahjongPair>.from(solutionOrder), positions: positions, layoutId: layoutId);
  Map<String, dynamic> toJson() => {'version': 1, 'layout': layoutId,
    'tiles': initialTiles.map((tile) => tile?.index).toList(),
    'solution': solutionOrder.map((p) => [p.first, p.second]).toList(),
    'moves': history.map((p) => [p.first, p.second]).toList()};
  factory MahjongBoard.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) throw const FormatException('Unsupported Mahjong save');
      final id = data['layout'] as String, positions = layout(data['layout'] as String);
      final ids = List<int>.from(data['tiles'] as List);
      if (ids.length != positions.length || ids.any((i) => i < 0 || i >= MahjongTile.values.length)) {
        throw const FormatException('Invalid tile set');
      }
      List<MahjongPair> pairs(String key) => (data[key] as List).map((p) {
        final list = List<int>.from(p as List);
        if (list.length != 2) throw const FormatException('Invalid pair');
        return MahjongPair(list[0], list[1]);
      }).toList();
      final solution = pairs('solution');
      final board = MahjongBoard(ids.map((i) => MahjongTile.values[i]).toList(), solution,
        positions: positions, layoutId: id);
      final proof = board.restart();
      for (final pair in solution) {
        if (!proof.remove(pair.first, pair.second)) throw const FormatException('Invalid solution proof');
      }
      if (!proof.complete) throw const FormatException('Incomplete solution proof');
      for (final pair in pairs('moves')) {
        if (!board.remove(pair.first, pair.second)) throw const FormatException('Illegal saved removal');
      }
      return board;
    } catch (error) { throw FormatException('Invalid Mahjong save: $error'); }
  }
  static String tileLabel(MahjongTile tile) {
    final i = tile.index;
    if (i < 9) return '${i + 1} Characters';
    if (i < 18) return '${i - 8} Bamboo';
    if (i < 27) return '${i - 17} Circles';
    return const ['Spring', 'Summer', 'Autumn', 'Winter', 'Plum', 'Orchid', 'Chrysanthemum', 'Bamboo flower',
      'East wind', 'South wind', 'West wind', 'North wind', 'Red dragon', 'Green dragon', 'White dragon'][i - 27];
  }
  static String tileGlyph(MahjongTile tile) => tileLabel(tile);
}
