import 'dart:math';
import 'dart:ui';

/// Two-sided sling-puck dexterity game. Coordinates are normalized to a
/// 1×1 tabletop; the visual board may be taller without changing physics.
class PassePuck {
  PassePuck(this.id, this.position, [this.velocity = Offset.zero]);
  final int id;
  Offset position;
  Offset velocity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.dx, 'y': position.dy,
        'vx': velocity.dx, 'vy': velocity.dy,
      };

  factory PassePuck.fromJson(Map<String, dynamic> data) => PassePuck(
        data['id'] as int,
        Offset((data['x'] as num).toDouble(), (data['y'] as num).toDouble()),
        Offset((data['vx'] as num).toDouble(), (data['vy'] as num).toDouble()),
      );
}

class PasseTrappeGame {
  PasseTrappeGame() {
    pucks = <PassePuck>[];
    shots = 0;
    for (var i = 0; i < 10; i++) {
      final col = i % 5;
      final top = i >= 5;
      pucks.add(PassePuck(i, Offset(.16 + col * .17,
          top ? (col.isEven ? .20 : .30) : (col.isEven ? .80 : .70))));
    }
  }

  PasseTrappeGame._(this.pucks, this.shots);

  static const double radius = .034;
  static const double gateWidth = .26;
  static const double mid = .5;
  static const double maxSpeed = 2.75;
  static const double friction = .987;

  late final List<PassePuck> pucks;
  late int shots;

  int countOnSide(int side) => pucks
      .where((puck) => side == 0
          ? puck.position.dy >= mid
          : puck.position.dy < mid).length;

  /// 0 bottom won, 1 top won. Clearing your half wins immediately.
  int? get winner {
    if (countOnSide(0) == 0) return 0;
    if (countOnSide(1) == 0) return 1;
    return null;
  }

  PassePuck? puckAt(Offset point, {int? side}) {
    PassePuck? candidate;
    var bestDistance = .075;
    for (final puck in pucks) {
      if (side != null &&
          (side == 0 ? puck.position.dy < mid : puck.position.dy >= mid)) {
        continue;
      }
      final distance = (puck.position - point).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        candidate = puck;
      }
    }
    return candidate;
  }

  /// Pull backward toward your own end and release to shoot forward.
  /// Positive pull.dy shoots upward from the bottom half, and vice versa.
  bool launch(int id, Offset pull) {
    if (winner != null || !pull.dx.isFinite || !pull.dy.isFinite ||
        pull.distance < .045) return false;
    PassePuck? puck;
    for (final item in pucks) {
      if (item.id == id) { puck = item; break; }
    }
    if (puck == null || puck.velocity.distance > .12) return false;
    final bottom = puck.position.dy >= mid;
    if ((bottom && pull.dy <= .02) || (!bottom && pull.dy >= -.02)) {
      return false;
    }
    final power = min(pull.distance, .24);
    final direction = -pull / pull.distance;
    puck.velocity = direction * (power * 9.2);
    shots++;
    return true;
  }

  /// A large tap-to-shoot fallback, usable without precise dragging.
  bool aimShoot(int id) {
    final puck = pucks.where((p) => p.id == id).firstOrNull;
    if (puck == null) return false;
    final toward = Offset(.5 - puck.position.dx,
        mid - puck.position.dy);
    if (toward.distance < .01) return false;
    // Aim the path at the center of the gate, then translate it to a pull.
    final vector = -toward / toward.distance * .20;
    return launch(id, vector);
  }

  /// A casual computer shoots from the upper half only when a puck rests.
  bool autoLaunch(Random random, {required int side, int level = 1}) {
    if (winner != null || side < 0 || side > 1) return false;
    final available = pucks.where((p) =>
        (side == 0 ? p.position.dy >= mid : p.position.dy < mid) &&
        p.velocity.distance < .12).toList()..shuffle(random);
    if (available.isEmpty) return false;
    final puck = available.first;
    final target = Offset(
        .5 + (random.nextDouble() - .5) * [.19, .10, .035][level.clamp(0, 2).toInt()],
        mid);
    final aim = target - puck.position;
    if (aim.distance < .02) return false;
    return launch(puck.id, -aim / aim.distance * (level == 0 ? .13 : .21));
  }

  void step(double seconds) {
    if (!seconds.isFinite || seconds <= 0 || winner != null) return;
    final count = max(1, (min(seconds, .10) / (1 / 180)).ceil());
    final delta = min(seconds, .10) / count;
    for (var sub = 0; sub < count; sub++) {
      for (final puck in pucks) {
        _move(puck, delta);
      }
      for (var i = 0; i < pucks.length; i++) {
        for (var j = i + 1; j < pucks.length; j++) {
          _collide(pucks[i], pucks[j]);
        }
      }
      if (winner != null) break;
    }
  }

  void _move(PassePuck puck, double dt) {
    var next = puck.position + puck.velocity * dt;
    var vx = puck.velocity.dx, vy = puck.velocity.dy;
    if (next.dx < radius) {
      next = Offset(radius, next.dy);
      vx = vx.abs() * .86;
    } else if (next.dx > 1 - radius) {
      next = Offset(1 - radius, next.dy);
      vx = -vx.abs() * .86;
    }
    if (next.dy < radius) {
      next = Offset(next.dx, radius);
      vy = vy.abs() * .86;
    } else if (next.dy > 1 - radius) {
      next = Offset(next.dx, 1 - radius);
      vy = -vy.abs() * .86;
    }
    final crosses = (puck.position.dy - mid) * (next.dy - mid) <= 0 &&
        (puck.position.dy - mid).abs() > 1e-8;
    if (crosses) {
      final open = (next.dx - .5).abs() < gateWidth / 2 - radius;
      if (!open) {
        next = Offset(next.dx,
            puck.position.dy > mid ? mid + radius : mid - radius);
        vy = -vy * .81;
      }
    } else if ((next.dy - mid).abs() < radius &&
        (next.dx - .5).abs() > gateWidth / 2 - radius) {
      final below = puck.position.dy >= mid;
      next = Offset(next.dx, below ? mid + radius : mid - radius);
      vy = below ? vy.abs() * .81 : -vy.abs() * .81;
    }
    puck.position = next;
    final decay = pow(friction, dt * 60).toDouble();
    puck.velocity = Offset(vx * decay, vy * decay);
    if (puck.velocity.distance < .014) puck.velocity = Offset.zero;
  }

  void _collide(PassePuck a, PassePuck b) {
    final diff = b.position - a.position;
    final distance = diff.distance;
    if (distance >= radius * 2) return;
    final normal = distance < 1e-7
        ? const Offset(1, 0)
        : diff / distance;
    final overlap = (radius * 2 - distance) / 2;
    Offset bounded(Offset p) => Offset(
          p.dx.clamp(radius, 1 - radius),
          p.dy.clamp(radius, 1 - radius),
        );
    a.position = bounded(a.position - normal * overlap);
    b.position = bounded(b.position + normal * overlap);
    final relative = b.velocity - a.velocity;
    final approach = relative.dx * normal.dx + relative.dy * normal.dy;
    if (approach >= 0) return;
    final impulse = normal * (-approach * .92);
    a.velocity -= impulse;
    b.velocity += impulse;
    for (final puck in [a, b]) {
      final speed = puck.velocity.distance;
      if (speed > maxSpeed) puck.velocity = puck.velocity / speed * maxSpeed;
    }
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'shots': shots,
        'pucks': [for (final puck in pucks) puck.toJson()],
      };

  factory PasseTrappeGame.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) {
        throw const FormatException('Unsupported Passe-Trappe save');
      }
      final list = (data['pucks'] as List).map((value) =>
          PassePuck.fromJson(Map<String, dynamic>.from(value as Map))).toList();
      final shots = data['shots'] as int;
      if (list.length != 10 || shots < 0 ||
          list.map((puck) => puck.id).toSet().length != 10 ||
          list.any((puck) =>
              puck.id < 0 || puck.id >= 10 ||
              !puck.position.dx.isFinite || !puck.position.dy.isFinite ||
              !puck.velocity.dx.isFinite || !puck.velocity.dy.isFinite ||
              puck.position.dx < radius - .0001 ||
              puck.position.dx > 1 - radius + .0001 ||
              puck.position.dy < radius - .0001 ||
              puck.position.dy > 1 - radius + .0001 ||
              puck.velocity.distance > maxSpeed + .001)) {
        throw const FormatException('Invalid puck positions or game state');
      }
      return PasseTrappeGame._(list, shots);
    } catch (error) {
      throw FormatException('Invalid Passe-Trappe save: $error');
    }
  }
}
