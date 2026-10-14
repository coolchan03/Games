import 'dart:math';

/// Chinese Checkers on the standard 121-hole star, in cube coordinates.
class Hole {
  const Hole(this.q, this.r);
  final int q, r;
  int get s => -q - r;
  @override
  bool operator ==(Object other) => other is Hole && other.q == q && other.r == r;
  @override
  int get hashCode => q * 31 + r;
  int distance(Hole o) => max((q - o.q).abs(), max((r - o.r).abs(), (s - o.s).abs()));
}

const _hexDirs = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)];

/// The six points of the star, clockwise from the bottom.
enum Corner { bottom, lowerLeft, upperLeft, top, upperRight, lowerRight }

extension CornerInfo on Corner {
  bool contains(Hole h) => switch (this) {
        Corner.bottom => h.r > 4,
        Corner.top => h.r < -4,
        Corner.lowerLeft => h.q < -4,
        Corner.upperRight => h.q > 4,
        Corner.upperLeft => h.s > 4,
        Corner.lowerRight => h.s < -4,
      };
  Corner get opposite => Corner.values[(index + 3) % 6];
  Hole get tip => switch (this) {
        Corner.bottom => const Hole(-4, 8),
        Corner.top => const Hole(4, -8),
        Corner.lowerLeft => const Hole(-8, 4),
        Corner.upperRight => const Hole(8, -4),
        Corner.upperLeft => const Hole(-4, -4),
        Corner.lowerRight => const Hole(4, 4),
      };
}

class CCMove {
  const CCMove(this.path);
  final List<Hole> path;
  Hole get from => path.first;
  Hole get to => path.last;
}

class ChineseCheckers {
  ChineseCheckers({this.players = 2, Random? random}) : rng = random ?? Random() {
    for (var q = -8; q <= 8; q++) {
      for (var r = -8; r <= 8; r++) {
        final s = -q - r;
        if (s < -8 || s > 8) continue;
        final up = q >= -4 && r >= -4 && s >= -4;
        final down = q <= 4 && r <= 4 && s <= 4;
        if (up || down) holes.add(Hole(q, r));
      }
    }
    corners = switch (players) {
      2 => [Corner.bottom, Corner.top],
      3 => [Corner.bottom, Corner.upperLeft, Corner.upperRight],
      _ => Corner.values.toList(),
    };
    for (var p = 0; p < corners.length; p++) {
      for (final h in holes) {
        if (corners[p].contains(h)) owner[h] = p;
      }
    }
  }

  final int players;
  final Random rng;
  final List<Hole> holes = [];
  late final List<Corner> corners;
  final Map<Hole, int> owner = {};
  int turn = 0;
  int? winner;
  int moves = 0;

  bool isHole(Hole h) => h.s >= -8 && h.s <= 8 && ((h.q >= -4 && h.r >= -4 && h.s >= -4) || (h.q <= 4 && h.r <= 4 && h.s <= 4)) && h.q.abs() <= 8 && h.r.abs() <= 8;

  List<Hole> destinations(Hole from) {
    final res = <Hole>{};
    for (final (dq, dr) in _hexDirs) {
      final n = Hole(from.q + dq, from.r + dr);
      if (isHole(n) && !owner.containsKey(n)) res.add(n);
    }
    // Chain hops.
    final seen = {from};
    final stack = [from];
    while (stack.isNotEmpty) {
      final c = stack.removeLast();
      for (final (dq, dr) in _hexDirs) {
        final over = Hole(c.q + dq, c.r + dr);
        final land = Hole(c.q + 2 * dq, c.r + 2 * dr);
        if (!owner.containsKey(over) || !isHole(land) || owner.containsKey(land) && land != from) continue;
        if (land == from || !seen.add(land)) continue;
        res.add(land);
        stack.add(land);
      }
    }
    return res.toList();
  }

  void move(Hole from, Hole to) {
    final p = owner.remove(from)!;
    owner[to] = p;
    moves++;
    if (_won(p)) {
      winner = p;
      return;
    }
    turn = (turn + 1) % corners.length;
  }

  bool _won(int p) {
    final target = corners[p].opposite;
    final mine = [for (final e in owner.entries) if (e.value == p) e.key];
    return mine.every(target.contains);
  }

  int pieceProgress(int p) {
    final tip = corners[p].opposite.tip;
    return [for (final e in owner.entries) if (e.value == p) e.key.distance(tip)].fold(0, (a, b) => a + b);
  }

  /// Greedy computer move: maximise distance gained toward the target tip,
  /// preferring stragglers; hard also avoids leaving pieces behind.
  (Hole, Hole) aiMove(int level) {
    final p = turn;
    final tip = corners[p].opposite.tip;
    final target = corners[p].opposite;
    (Hole, Hole)? best;
    var bestScore = -1e9;
    for (final from in [for (final e in owner.entries) if (e.value == p) e.key]) {
      for (final to in destinations(from)) {
        final gain = from.distance(tip) - to.distance(tip);
        var score = gain * 10.0;
        if (level >= 1) {
          score += from.distance(tip) * .5; // move rear pieces
          if (target.contains(from) && !target.contains(to)) score -= 50;
        }
        if (level == 2) {
          // Stay near the centre line toward the tip.
          final off = (to.q - tip.q).abs() + (to.r - tip.r).abs() + (to.s - tip.s).abs() - 2 * to.distance(tip);
          score -= off * .3;
        }
        score += rng.nextDouble() * (level == 0 ? 12 : 1);
        if (score > bestScore) {
          bestScore = score;
          best = (from, to);
        }
      }
    }
    return best!;
  }
}
