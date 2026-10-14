import 'dart:math';

const fleet = [('Carrier', 5), ('Battleship', 4), ('Cruiser', 3), ('Submarine', 3), ('Destroyer', 2)];

class Ship {
  Ship(this.name, this.cells);
  final String name;
  final List<int> cells;
}

/// One player's 10×10 ocean.
class Ocean {
  Ocean(Random rng) {
    for (final (name, len) in fleet) {
      while (true) {
        final horizontal = rng.nextBool();
        final r = rng.nextInt(horizontal ? 10 : 11 - len);
        final c = rng.nextInt(horizontal ? 11 - len : 10);
        final cells = [for (var k = 0; k < len; k++) horizontal ? r * 10 + c + k : (r + k) * 10 + c];
        if (cells.any((x) => ships.any((s) => s.cells.contains(x)))) continue;
        ships.add(Ship(name, cells));
        break;
      }
    }
  }

  final List<Ship> ships = [];
  final Set<int> shots = {};

  Ship? shipAt(int cell) {
    for (final s in ships) {
      if (s.cells.contains(cell)) return s;
    }
    return null;
  }

  bool sunk(Ship s) => s.cells.every(shots.contains);
  bool get defeated => ships.every(sunk);

  /// Fires at [cell]; returns 'miss', 'hit' or the name of a sunk ship.
  String fire(int cell) {
    shots.add(cell);
    final s = shipAt(cell);
    if (s == null) return 'miss';
    return sunk(s) ? s.name : 'hit';
  }
}

/// Hunt-and-target computer gunner. Hard mode uses a probability density
/// of where the remaining ships can still fit.
class Gunner {
  Gunner(this.level, this.rng);
  final int level;
  final Random rng;

  int pick(Ocean target) {
    final open = [for (var i = 0; i < 100; i++) if (!target.shots.contains(i)) i];
    if (level == 0) return open[rng.nextInt(open.length)];
    final hitsUnsunk = [
      for (final i in target.shots)
        if (target.shipAt(i) != null && !target.sunk(target.shipAt(i)!)) i
    ];
    if (hitsUnsunk.isNotEmpty) {
      // Target mode: extend lines of hits, else probe neighbours.
      final candidates = <int>[];
      for (final h in hitsUnsunk) {
        for (final (dr, dc) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final r = h ~/ 10 + dr, c = h % 10 + dc;
          if (r < 0 || r > 9 || c < 0 || c > 9) continue;
          final n = r * 10 + c;
          if (target.shots.contains(n)) continue;
          final back = (h ~/ 10 - dr) * 10 + h % 10 - dc;
          final inLine = hitsUnsunk.contains(back);
          candidates.add(n);
          if (inLine) candidates.addAll([n, n, n]);
        }
      }
      if (candidates.isNotEmpty) return candidates[rng.nextInt(candidates.length)];
    }
    if (level == 1) {
      final parity = open.where((i) => (i ~/ 10 + i % 10).isEven).toList();
      final pool = parity.isEmpty ? open : parity;
      return pool[rng.nextInt(pool.length)];
    }
    final density = List.filled(100, 0);
    for (final s in target.ships.where((s) => !target.sunk(s))) {
      final len = s.cells.length;
      for (var r = 0; r < 10; r++) {
        for (var c = 0; c < 10; c++) {
          for (final horizontal in [true, false]) {
            if (horizontal ? c + len > 10 : r + len > 10) continue;
            final cells = [for (var k = 0; k < len; k++) horizontal ? r * 10 + c + k : (r + k) * 10 + c];
            if (cells.any(target.shots.contains)) continue;
            for (final x in cells) {
              density[x]++;
            }
          }
        }
      }
    }
    var best = open.first;
    for (final i in open) {
      if (density[i] > density[best] || (density[i] == density[best] && rng.nextBool())) best = i;
    }
    return best;
  }
}
