// Port of the grid generator, solvability search and move rules of
// "Inertia" from Simon Tatham's Portable Puzzle Collection (inertia.c,
// MIT licence, Copyright (c) 2004-2014 Simon Tatham and contributors).
import 'dart:math';

enum Cell { blank, gem, mine, stop, wall, start, possGem }

const _directions = 8;
int dirX(int d) => d & 3 != 0 ? ((d & 7) > 4 ? -1 : 1) : 0;
int dirY(int d) => dirX(d + 6);

class InertiaGame {
  InertiaGame({this.w = 10, this.h = 10, Random? random}) : rng = random ?? Random() {
    grid = _gengrid();
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == Cell.start) {
        grid[i] = Cell.stop;
        px = i % w;
        py = i ~/ w;
      }
    }
    gems = grid.where((c) => c == Cell.gem).length;
    totalGems = gems;
  }

  final int w, h;
  final Random rng;
  late List<Cell> grid;
  int px = 0, py = 0;
  late int gems;
  late int totalGems;
  bool dead = false;
  int moves = 0;
  final List<(List<Cell>, int, int, int, bool)> _history = [];

  bool get won => gems == 0 && !dead;

  Cell at(List<Cell> g, int x, int y) => (x < 0 || x >= w || y < 0 || y >= h) ? Cell.wall : g[y * w + x];

  bool _canGo(List<Cell> g, int x1, int y1, int d1, int x2, int y2, int d2) {
    final here = at(g, x1, y1);
    if (here == Cell.wall || here == Cell.mine) return false;
    if (x2 == x1 &&
        y2 == y1 &&
        (here == Cell.stop || here == Cell.start || at(g, x1 + dirX(d1), y1 + dirY(d1)) == Cell.wall)) {
      return true;
    }
    if (x2 == x1 + dirX(d1) && y2 == y1 + dirY(d1) && d1 == d2) {
      final next = at(g, x2, y2);
      return next == Cell.blank || next == Cell.gem || next == Cell.stop || next == Cell.start;
    }
    return false;
  }

  /// Marks blank squares that can be collected on a round trip from the
  /// start as possible gem squares; returns how many there are.
  int _findGemCandidates(List<Cell> g) {
    final wh = w * h;
    final from = List.filled(wh * _directions, false);
    final to = List.filled(wh * _directions, false);
    final s = g.indexOf(Cell.start);
    final sx = s % w, sy = s ~/ w;
    for (var pass = 0; pass < 2; pass++) {
      final reachable = pass == 0 ? from : to;
      final sign = pass == 0 ? 1 : -1;
      final queue = <int>[];
      for (var d = 0; d < _directions; d++) {
        final idx = (sy * w + sx) * _directions + d;
        queue.add(idx);
        reachable[idx] = true;
      }
      var head = 0;
      while (head < queue.length) {
        final index = queue[head++];
        final dir = index % _directions;
        final x = (index ~/ _directions) % w;
        final y = index ~/ (w * _directions);
        for (var n = -1; n < _directions; n++) {
          int x2, y2, d2;
          if (n < 0) {
            x2 = x + sign * dirX(dir);
            y2 = y + sign * dirY(dir);
            d2 = dir;
          } else {
            x2 = x;
            y2 = y;
            d2 = n;
          }
          if (x2 < 0 || x2 >= w || y2 < 0 || y2 >= h) continue;
          final i2 = (y2 * w + x2) * _directions + d2;
          if (reachable[i2]) continue;
          final ok = pass == 0 ? _canGo(g, x, y, dir, x2, y2, d2) : _canGo(g, x2, y2, d2, x, y, dir);
          if (ok) {
            queue.add(i2);
            reachable[i2] = true;
          }
        }
      }
    }
    var count = 0;
    for (var i = 0; i < wh; i++) {
      if (g[i] != Cell.blank) continue;
      for (var d = 0; d < _directions; d++) {
        if (from[i * _directions + d] && to[i * _directions + d]) {
          g[i] = Cell.possGem;
          count++;
          break;
        }
      }
    }
    return count;
  }

  List<Cell> _gengrid() {
    final wh = w * h;
    var threshold = 2, tries = 0;
    while (true) {
      final g = <Cell>[
        for (var j = 0; j < wh ~/ 5; j++) Cell.wall,
        for (var j = 0; j < wh ~/ 5; j++) Cell.stop,
        for (var j = 0; j < wh ~/ 5; j++) Cell.mine,
        Cell.start,
      ];
      while (g.length < wh) {
        g.add(Cell.blank);
      }
      g.shuffle(rng);
      if (_findGemCandidates(g) < wh ~/ 5) continue;
      // Reject levels where some area is far from any reachable gem square.
      final dist = List.filled(wh, -1);
      final list = <int>[];
      for (var i = 0; i < wh; i++) {
        if (g[i] == Cell.possGem) {
          dist[i] = 0;
          list.add(i);
        }
      }
      var head = 0, maxdist = 0;
      while (head < list.length) {
        final pos = list[head++];
        maxdist = max(maxdist, dist[pos]);
        final x = pos % w, y = pos ~/ w;
        for (var d = 0; d < _directions; d++) {
          final x2 = x + dirX(d), y2 = y + dirY(d);
          if (x2 >= 0 && x2 < w && y2 >= 0 && y2 < h && dist[y2 * w + x2] < 0) {
            dist[y2 * w + x2] = dist[pos] + 1;
            list.add(y2 * w + x2);
          }
        }
      }
      if (maxdist > threshold) {
        if (++tries == 50) {
          threshold++;
          tries = 0;
        }
        continue;
      }
      final poss = [for (var i = 0; i < wh; i++) if (g[i] == Cell.possGem) i]..shuffle(rng);
      for (var i = 0; i < poss.length; i++) {
        g[poss[i]] = i < wh ~/ 5 ? Cell.gem : Cell.blank;
      }
      return g;
    }
  }

  bool canMove(int d) => !dead && !won && at(grid, px + dirX(d), py + dirY(d)) != Cell.wall;

  /// Slides in direction [d] until a stop, a wall, or a mine.
  bool move(int d) {
    if (!canMove(d)) return false;
    _history.add((List.of(grid), px, py, gems, dead));
    moves++;
    while (true) {
      px += dirX(d);
      py += dirY(d);
      final i = py * w + px;
      if (grid[i] == Cell.gem) {
        grid[i] = Cell.blank;
        gems--;
      }
      if (grid[i] == Cell.mine) {
        dead = true;
        break;
      }
      if (grid[i] == Cell.stop || at(grid, px + dirX(d), py + dirY(d)) == Cell.wall) break;
    }
    return true;
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    grid = h.$1;
    px = h.$2;
    py = h.$3;
    gems = h.$4;
    dead = h.$5;
    moves--;
  }
}

/// The 20 numbered Inertia levels: boards grow from 6×6 to 12×12, with a
/// fifth of the squares each walls, stops, mines and gems. Each level comes
/// from a fixed seed, and the generator keeps every gem reachable.
class InertiaLevels {
  static const sizes = [
    6, 6, 6, 7, 7, 7, 8, 8, 8, 8,
    9, 9, 9, 10, 10, 10, 10, 12, 12, 12,
  ];

  static InertiaGame build(int level) {
    final size = sizes[level - 1];
    return InertiaGame(w: size, h: size, random: Random(5800 + level * 61));
  }
}
