import 'dart:math';

/// Sokoban with generated levels. A level is built backwards from the
/// solved position: boxes start on their goals and the player *pulls* them
/// around. Reversing those pulls gives a sequence of pushes that solves the
/// level, so every generated level is solvable.
class SokobanLevel {
  SokobanLevel(this.w, this.h, this.walls, this.goals, this.boxes, this.player, this.pulls);
  final int w, h;
  final Set<int> walls;
  final Set<int> goals;
  final Set<int> boxes;
  final int player;

  /// Number of pulls used when generating (a rough difficulty measure).
  final int pulls;

  static const dirs = [(0, -1), (1, 0), (0, 1), (-1, 0)];

  static SokobanLevel generate(int seed, {int size = 7, int boxCount = 3}) {
    final rng = Random(seed);
    SokobanLevel? best;
    var bestScore = -1;
    for (var attempt = 0; attempt < 12; attempt++) {
      final lvl = _attempt(rng, size, boxCount);
      if (lvl == null) continue;
      // Prefer levels where boxes travelled far from their goals.
      var score = 0;
      for (final b in lvl.boxes) {
        score += lvl.goals.map((g) => (g % lvl.w - b % lvl.w).abs() + (g ~/ lvl.w - b ~/ lvl.w).abs()).reduce(min);
      }
      score += lvl.boxes.difference(lvl.goals).length * 5;
      if (score > bestScore) {
        bestScore = score;
        best = lvl;
      }
    }
    return best ?? generate(seed + 7919, size: size, boxCount: boxCount);
  }

  static SokobanLevel? _attempt(Random rng, int size, int boxCount) {
    final w = size + 2, h = size + 2;
    final walls = <int>{};
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final border = x == 0 || y == 0 || x == w - 1 || y == h - 1;
        if (border || rng.nextDouble() < .24) walls.add(y * w + x);
      }
    }
    // Keep the largest connected floor area.
    final floor = [for (var i = 0; i < w * h; i++) if (!walls.contains(i)) i];
    final seen = <int>{};
    List<int> biggest = [];
    for (final f in floor) {
      if (seen.contains(f)) continue;
      final comp = [f];
      seen.add(f);
      for (var k = 0; k < comp.length; k++) {
        for (final (dx, dy) in dirs) {
          final n = comp[k] + dy * w + dx;
          if (!walls.contains(n) && seen.add(n)) comp.add(n);
        }
      }
      if (comp.length > biggest.length) biggest = comp;
    }
    if (biggest.length < size * size * .55) return null;
    final keep = biggest.toSet();
    for (final f in floor) {
      if (!keep.contains(f)) walls.add(f);
    }
    // Goals away from corners so boxes can be pulled off them.
    int openSides(int c) => dirs.where((d) => !walls.contains(c + d.$2 * w + d.$1)).length;
    final candidates = biggest.where((c) => openSides(c) >= 3).toList()..shuffle(rng);
    if (candidates.length < boxCount + 1) return null;
    final goals = candidates.take(boxCount).toSet();
    final boxes = Set<int>.of(goals);
    var player = biggest.firstWhere((c) => !boxes.contains(c));
    var pulls = 0;
    for (var step = 0; step < 120; step++) {
      final reach = _reachable(w, walls, boxes, player);
      final options = <(int, int, int)>[]; // (standAt, box, dir index)
      for (final p in reach) {
        for (var d = 0; d < 4; d++) {
          final (dx, dy) = dirs[d];
          final box = p - dy * w - dx; // box behind the player
          final dest = p + dy * w + dx; // player steps away
          if (boxes.contains(box) && !walls.contains(dest) && !boxes.contains(dest)) {
            options.add((p, box, d));
          }
        }
      }
      if (options.isEmpty) break;
      final (p, box, d) = options[rng.nextInt(options.length)];
      final (dx, dy) = dirs[d];
      boxes
        ..remove(box)
        ..add(p);
      player = p + dy * w + dx;
      pulls++;
    }
    if (boxes.difference(goals).length < max(1, boxCount - 1)) return null;
    // Let the player start anywhere they could have walked to.
    final reach = _reachable(w, walls, boxes, player).toList()..shuffle(rng);
    return SokobanLevel(w, h, walls, goals, boxes, reach.first, pulls);
  }

  static Set<int> _reachable(int w, Set<int> walls, Set<int> boxes, int from) {
    final seen = {from};
    final queue = [from];
    for (var k = 0; k < queue.length; k++) {
      for (final (dx, dy) in dirs) {
        final n = queue[k] + dy * w + dx;
        if (!walls.contains(n) && !boxes.contains(n) && seen.add(n)) queue.add(n);
      }
    }
    return seen;
  }
}

class SokobanGame {
  SokobanGame(this.level)
      : boxes = Set.of(level.boxes),
        player = level.player;

  final SokobanLevel level;
  Set<int> boxes;
  int player;
  int moves = 0, pushes = 0;
  final List<(Set<int>, int, int, int)> _history = [];

  bool get solved => boxes.difference(level.goals).isEmpty;
  bool get canUndo => _history.isNotEmpty;

  /// Moves one step in direction [d] (0 up, 1 right, 2 down, 3 left).
  bool step(int d) {
    if (solved) return false;
    final (dx, dy) = SokobanLevel.dirs[d];
    final w = level.w;
    final next = player + dy * w + dx;
    if (level.walls.contains(next)) return false;
    if (boxes.contains(next)) {
      final beyond = next + dy * w + dx;
      if (level.walls.contains(beyond) || boxes.contains(beyond)) return false;
      _history.add((Set.of(boxes), player, moves, pushes));
      boxes
        ..remove(next)
        ..add(beyond);
      pushes++;
    } else {
      _history.add((Set.of(boxes), player, moves, pushes));
    }
    player = next;
    moves++;
    return true;
  }

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    boxes = h.$1;
    player = h.$2;
    moves = h.$3;
    pushes = h.$4;
  }

  /// Walks to [target] along the shortest path without pushing; returns
  /// false if it is not reachable.
  bool walkTo(int target) {
    final w = level.w;
    final prev = <int, int>{player: -1};
    final queue = [player];
    for (var k = 0; k < queue.length && !prev.containsKey(target); k++) {
      for (var d = 0; d < 4; d++) {
        final (dx, dy) = SokobanLevel.dirs[d];
        final n = queue[k] + dy * w + dx;
        if (level.walls.contains(n) || boxes.contains(n) || prev.containsKey(n)) continue;
        prev[n] = queue[k];
        queue.add(n);
      }
    }
    if (!prev.containsKey(target) || target == player) return false;
    final path = <int>[];
    for (var c = target; c != player; c = prev[c]!) {
      path.add(c);
    }
    for (final c in path.reversed) {
      final diff = c - player;
      final d = diff == -w ? 0 : diff == 1 ? 1 : diff == w ? 2 : 3;
      step(d);
    }
    return true;
  }
}
