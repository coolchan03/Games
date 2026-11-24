import 'dart:math';

import '../../common/level_kit.dart';

import 'mahjong_layouts.dart';
import 'mahjong_tile.dart';

/// A tile slot in a layered layout, in half-tile units.
class Slot {
  const Slot(this.x, this.y, this.z);
  final int x, y, z;
}

class Layout {
  Layout(this.name, this.width, this.height, this.slots);
  final String name;
  final int width, height;
  final List<Slot> slots;

  static List<Layout> all() => [
        for (final (name, w, h, enc) in mahjongLayouts)
          Layout(name, w, h, [
            for (var i = 0; i + 2 < enc.length; i += 3)
              Slot(enc.codeUnitAt(i) - 48, enc.codeUnitAt(i + 1) - 48, enc.codeUnitAt(i + 2) - 48),
          ]),
        _flat(),
      ];

  /// Gentle single-layer 12 × 6 layout for beginners.
  static Layout _flat() => Layout('Beginner', 24, 12, [
        for (var y = 0; y < 6; y++)
          for (var x = 0; x < 12; x++) Slot(x * 2, y * 2, 0),
      ]);
}

/// Layered Mahjong Solitaire using ED-Mahjong's tile matching rules.
/// Boards are dealt by simulating a full removal sequence, so every deal is
/// solvable; "shuffle" re-deals the remaining tiles the same way.
class LayeredBoard {
  LayeredBoard(this.layout, {Random? random}) : rng = random ?? Random() {
    tiles = List.filled(layout.slots.length, null);
    _buildNeighbours();
    _deal(List.generate(layout.slots.length, (i) => i), _fullSet(layout.slots.length));
  }

  final Layout layout;
  final Random rng;
  late List<MahjongTile?> tiles;
  final List<(int, int, MahjongTile, MahjongTile)> history = [];
  int shuffles = 0;

  /// The removal order used to deal the current tiles (a known solution).
  List<(int, int)> solution = [];

  late final List<List<int>> _above, _left, _right;

  void _buildNeighbours() {
    final s = layout.slots;
    _above = List.generate(s.length, (_) => []);
    _left = List.generate(s.length, (_) => []);
    _right = List.generate(s.length, (_) => []);
    for (var i = 0; i < s.length; i++) {
      for (var j = 0; j < s.length; j++) {
        if (i == j) continue;
        final dx = s[j].x - s[i].x, dy = (s[j].y - s[i].y).abs();
        if (s[j].z == s[i].z + 1 && dx.abs() < 2 && dy < 2) _above[i].add(j);
        if (s[j].z == s[i].z && dy < 2) {
          if (dx == -2) _left[i].add(j);
          if (dx == 2) _right[i].add(j);
        }
      }
    }
  }

  /// Faces for [n] tiles as pairs that match each other.
  List<(MahjongTile, MahjongTile)> _fullSet(int n) {
    final pairs = <(MahjongTile, MahjongTile)>[];
    for (final t in MahjongTile.values) {
      if (isFlower(t) || isSeason(t)) continue;
      pairs
        ..add((t, t))
        ..add((t, t));
    }
    pairs
      ..add((MahjongTile.FLOWER_1, MahjongTile.FLOWER_2))
      ..add((MahjongTile.FLOWER_3, MahjongTile.FLOWER_4))
      ..add((MahjongTile.SEASON_1, MahjongTile.SEASON_2))
      ..add((MahjongTile.SEASON_3, MahjongTile.SEASON_4));
    pairs.shuffle(rng);
    return pairs.take(n ~/ 2).toList();
  }

  bool freeIn(int i, Set<int> present) => _freeIn(i, present);

  bool _freeIn(int i, Set<int> present) {
    if (_above[i].any(present.contains)) return false;
    return !_left[i].any(present.contains) || !_right[i].any(present.contains);
  }

  /// Assigns [pairs] to [indices] following a random legal removal order.
  void _deal(List<int> indices, List<(MahjongTile, MahjongTile)> pairs) {
    for (var attempt = 0; attempt < 400; attempt++) {
      final present = indices.toSet();
      final order = <(int, int)>[];
      var ok = true;
      while (present.isNotEmpty) {
        final free = [for (final i in present) if (_freeIn(i, present)) i];
        if (free.length < 2) {
          ok = false;
          break;
        }
        free.shuffle(rng);
        final a = free.removeLast();
        final b = free[rng.nextInt(free.length)];
        order.add((a, b));
        present
          ..remove(a)
          ..remove(b);
      }
      if (!ok) continue;
      solution = order;
      final shuffled = pairs.toList()..shuffle(rng);
      for (var k = 0; k < order.length; k++) {
        tiles[order[k].$1] = shuffled[k].$1;
        tiles[order[k].$2] = shuffled[k].$2;
      }
      return;
    }
    throw StateError('Could not deal ${layout.name}');
  }

  int get remaining => tiles.where((t) => t != null).length;
  bool get won => remaining == 0;

  Set<int> get _present => {for (var i = 0; i < tiles.length; i++) if (tiles[i] != null) i};

  bool isFree(int i) => tiles[i] != null && _freeIn(i, _present);

  List<(int, int)> get moves => movesIn(_present);

  /// Matching free pairs when exactly the slots in [present] hold tiles.
  List<(int, int)> movesIn(Set<int> present) {
    final free = [for (final i in present) if (_freeIn(i, present)) i];
    final res = <(int, int)>[];
    for (var a = 0; a < free.length; a++) {
      for (var b = a + 1; b < free.length; b++) {
        if (doMatch(tiles[free[a]]!, tiles[free[b]]!)) res.add((free[a], free[b]));
      }
    }
    return res;
  }

  /// A last pair that can never meet: both tiles are the only two left of
  /// their kind and one lies (directly) on top of the other. This is a
  /// *proof* the board cannot be cleared; no search is needed.
  bool get hasStackedLastPair {
    final present = _present;
    for (final i in present) {
      for (final j in _above[i]) {
        if (present.contains(j) && doMatch(tiles[i]!, tiles[j]!)) {
          final matches = present.where((k) => doMatch(tiles[i]!, tiles[k]!)).length;
          if (matches == 2) return true;
        }
      }
    }
    return false;
  }

  late final MahjongTrapMonitor monitor = MahjongTrapMonitor(this);

  bool remove(int a, int b) {
    if (a == b || !isFree(a) || !isFree(b) || !doMatch(tiles[a]!, tiles[b]!)) return false;
    history.add((a, b, tiles[a]!, tiles[b]!));
    tiles[a] = null;
    tiles[b] = null;
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final (a, b, ta, tb) = history.removeLast();
    tiles[a] = ta;
    tiles[b] = tb;
  }

  /// Re-deals the remaining tiles into a solvable arrangement.
  void shuffle() {
    final idx = _present.toList();
    final faces = [for (final i in idx) tiles[i]!];
    // Pair up remaining faces by match class.
    final pairs = <(MahjongTile, MahjongTile)>[];
    final pool = faces.toList();
    while (pool.isNotEmpty) {
      final a = pool.removeLast();
      final j = pool.indexWhere((t) => doMatch(a, t));
      pairs.add((a, pool.removeAt(j)));
    }
    for (final i in idx) {
      tiles[i] = null;
    }
    _deal(idx, pairs);
    history.clear();
    shuffles++;
  }
}

/// The 20 numbered Mahjong Solitaire levels: two deals of the flat
/// Beginner layout, then each KMahjongg layout dealt from fixed seeds. Every
/// deal is built from a full removal sequence, so all levels are solvable.
class MahjongLevels {
  static final List<Layout> _layouts = Layout.all();

  /// (layout index in [Layout.all], deal seed) for each level.
  static final List<(int, int)> specs = () {
    final beginner = _layouts.length - 1;
    return [
      (beginner, 1),
      (beginner, 2),
      for (var i = 0; i < beginner; i++) (i, 1),
      for (var i = 0; i < beginner; i++) (i, 2),
      (beginner - 1, 3),
      (beginner - 2, 3),
    ];
  }();

  static Layout layoutFor(int level) => _layouts[specs[level - 1].$1];

  static LayeredBoard build(int level) {
    final (index, deal) = specs[level - 1];
    return LayeredBoard(_layouts[index], random: Random(9100 + index * 97 + deal * 13));
  }
}

/// Position graph for the solver: which slots still hold a tile.
class MahjongPuzzle extends SearchPuzzle<List<bool>> {
  MahjongPuzzle(this.board);
  final LayeredBoard board;

  Set<int> _set(List<bool> s) => {for (var i = 0; i < s.length; i++) if (s[i]) i};

  @override
  String key(List<bool> s) => s.map((b) => b ? '1' : '0').join();

  @override
  bool isGoal(List<bool> s) => !s.contains(true);

  @override
  Iterable<List<bool>> successors(List<bool> s) {
    final present = _set(s);
    final moves = board.movesIn(present);
    // Try the moves that open up the most tiles first: winning lines are
    // plentiful, so this order finds one quickly.
    int opened((int, int) m) {
      final after = {...present}..remove(m.$1)..remove(m.$2);
      return after.where((i) => board.freeIn(i, after)).length;
    }

    // The dealing order is a known winning line: while the player's own
    // pairs agree with it, following it finds a solution almost instantly.
    final known = {
      for (final (a, b) in board.solution) (a < b ? a : b) * 1000 + (a < b ? b : a)
    };
    int score((int, int) m) =>
        (known.contains((m.$1 < m.$2 ? m.$1 : m.$2) * 1000 + (m.$1 < m.$2 ? m.$2 : m.$1))
            ? 1000
            : 0) +
        opened(m);

    final scored = [for (final m in moves) (score(m), m)]
      ..sort((a, b) => b.$1.compareTo(a.$1));
    return [
      for (final (_, m) in scored)
        [...s]
          ..[m.$1] = false
          ..[m.$2] = false
    ];
  }
}

/// Proven-winnable / proven-lost / unknown for the current board, plus a hint
/// that never walks into a dead end.
class MahjongTrapMonitor {
  MahjongTrapMonitor(this.board)
      : _monitor = TrapMonitor<List<bool>>(MahjongPuzzle(board),
            maxNodes: 12000, depthFirst: true);

  final LayeredBoard board;
  final TrapMonitor<List<bool>> _monitor;

  List<bool> get _state => [for (final t in board.tiles) t != null];

  Solvability analyze() {
    if (board.won) return Solvability.solvable;
    if (board.hasStackedLastPair) return Solvability.unsolvable;
    return _monitor.analyze(_state);
  }

  /// True only when the board is *proven* unwinnable without a shuffle.
  bool get trapped => analyze() == Solvability.unsolvable;

  /// A pair whose removal keeps the board winnable, or null if none is known.
  (int, int)? safeHint() {
    final next = _monitor.hint(_state);
    if (next == null) return null;
    final gone = [
      for (var i = 0; i < next.length; i++)
        if (board.tiles[i] != null && !next[i]) i
    ];
    return gone.length == 2 ? (gone[0], gone[1]) : null;
  }
}
