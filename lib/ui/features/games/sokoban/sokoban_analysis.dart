import '../common/level_kit.dart';
import 'sokoban_engine.dart';

/// Sound deadlock detection for Sokoban: it only reports "trapped" when no
/// sequence of pushes can ever finish the level, so a player is never told
/// they are stuck when they are not.
///
/// Two proofs are used:
///  * **Dead squares** - a box on a square from which it can never be pushed
///    onto any goal (found by pulling boxes backwards from the goals).
///  * **Frozen boxes** - a box that cannot move along either axis (walls, dead
///    squares or other frozen boxes on both sides) and is not on a goal.
class SokobanAnalysis {
  SokobanAnalysis(this.level) : alive = _aliveSquares(level);

  final SokobanLevel level;

  /// Squares from which a box can still be pushed to some goal.
  final Set<int> alive;

  static Set<int> _aliveSquares(SokobanLevel level) {
    final w = level.w;
    final alive = <int>{...level.goals};
    final queue = [...level.goals];
    for (var k = 0; k < queue.length; k++) {
      final s = queue[k];
      for (final (dx, dy) in SokobanLevel.dirs) {
        final d = dy * w + dx;
        final from = s - d; // the box could have been pushed from here...
        final pusher = s - 2 * d; // ...by a player standing here
        if (level.walls.contains(from) || level.walls.contains(pusher)) continue;
        if (alive.add(from)) queue.add(from);
      }
    }
    return alive;
  }

  bool _isWall(int i) => level.walls.contains(i);

  bool _blocked(int box, int a, int b, Set<int> boxes, Set<int> visiting) {
    // Axis through the two neighbours a and b.
    if (_isWall(a) || _isWall(b)) return true;
    if (!alive.contains(a) && !alive.contains(b)) return true;
    for (final n in [a, b]) {
      if (boxes.contains(n) && !visiting.contains(n)) {
        if (_frozenBox(n, boxes, {...visiting, box})) return true;
      } else if (boxes.contains(n)) {
        return true; // a cycle of mutually blocking boxes
      }
    }
    return false;
  }

  bool _frozenBox(int box, Set<int> boxes, Set<int> visiting) {
    final w = level.w;
    final v = {...visiting, box};
    return _blocked(box, box - 1, box + 1, boxes, v) &&
        _blocked(box, box - w, box + w, boxes, v);
  }

  /// True when [boxes] can no longer all reach goals.
  bool trapped(Set<int> boxes) {
    for (final b in boxes) {
      if (!alive.contains(b)) return true;
      if (!level.goals.contains(b) && _frozenBox(b, boxes, const {})) return true;
    }
    return false;
  }
}

/// Position graph over pushes (the player walks freely between pushes), for
/// the shared solver: used to verify levels and to hint.
class SokobanPuzzle extends SearchPuzzle<({Set<int> boxes, int player})> {
  SokobanPuzzle(this.level);
  final SokobanLevel level;

  Set<int> _reach(Set<int> boxes, int from) {
    final seen = <int>{from};
    final queue = [from];
    for (var k = 0; k < queue.length; k++) {
      for (final (dx, dy) in SokobanLevel.dirs) {
        final n = queue[k] + dy * level.w + dx;
        if (!level.walls.contains(n) && !boxes.contains(n) && seen.add(n)) {
          queue.add(n);
        }
      }
    }
    return seen;
  }

  @override
  String key(({Set<int> boxes, int player}) s) {
    final boxes = s.boxes.toList()..sort();
    final reach = _reach(s.boxes, s.player);
    return '${boxes.join(',')}/${reach.reduce((a, b) => a < b ? a : b)}';
  }

  @override
  bool isGoal(({Set<int> boxes, int player}) s) =>
      s.boxes.length == level.goals.length && s.boxes.containsAll(level.goals);

  @override
  Iterable<({Set<int> boxes, int player})> successors(
      ({Set<int> boxes, int player}) s) sync* {
    final reach = _reach(s.boxes, s.player);
    for (final box in s.boxes) {
      for (final (dx, dy) in SokobanLevel.dirs) {
        final d = dy * level.w + dx;
        if (!reach.contains(box - d)) continue;
        final to = box + d;
        if (level.walls.contains(to) || s.boxes.contains(to)) continue;
        yield (boxes: {...s.boxes}..remove(box)..add(to), player: box);
      }
    }
  }
}
