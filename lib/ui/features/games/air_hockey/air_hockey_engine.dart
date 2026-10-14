import 'dart:math';
import 'dart:ui';

/// Lightweight air hockey physics in table units: the table is 1 wide and
/// 1.6 tall; the computer (or player 2) defends the top goal.
class AirHockeyPhysics {
  AirHockeyPhysics({Random? random}) : rng = random ?? Random() {
    faceOff(towardTop: rng.nextBool());
  }

  static const width = 1.0, height = 1.6;
  static const puckR = .035, paddleR = .07, goalWidth = .34;
  static const maxPuckSpeed = 3.2;

  final Random rng;
  Offset puck = Offset.zero, puckV = Offset.zero;
  Offset bottom = const Offset(.5, 1.45), top = const Offset(.5, .15);
  Offset bottomV = Offset.zero, topV = Offset.zero;
  final scores = [0, 0]; // [bottom, top]
  int? lastGoal; // 0 bottom scored, 1 top scored
  double pause = 0;

  void faceOff({required bool towardTop}) {
    puck = const Offset(.5, .8);
    puckV = Offset((rng.nextDouble() - .5) * .3, towardTop ? -.25 : .25);
    bottom = const Offset(.5, 1.45);
    top = const Offset(.5, .15);
    pause = .6;
  }

  /// Moves a paddle toward [target], limited to its own half.
  Offset clampPaddle(Offset p, {required bool isTop}) {
    final x = p.dx.clamp(paddleR, width - paddleR);
    final y = isTop ? p.dy.clamp(paddleR, height / 2 - paddleR) : p.dy.clamp(height / 2 + paddleR, height - paddleR);
    return Offset(x, y);
  }

  void setBottom(Offset target, double dt) {
    final next = clampPaddle(target, isTop: false);
    bottomV = dt > 0 ? (next - bottom) / dt : Offset.zero;
    bottom = next;
  }

  void setTop(Offset target, double dt) {
    final next = clampPaddle(target, isTop: true);
    topV = dt > 0 ? (next - top) / dt : Offset.zero;
    top = next;
  }

  /// Simple computer defender/attacker for the top paddle.
  void aiStep(double dt, int level) {
    final speed = [0.7, 1.2, 1.9][level];
    Offset target;
    if (puck.dy < height / 2 + .05 && (puckV.dy < .2 || puck.dy < top.dy + .2)) {
      // Puck on our side: get behind it and strike toward the bottom goal.
      final aim = Offset(width / 2 + (rng.nextDouble() - .5) * .2, height);
      final dir = aim - puck;
      final n = dir / max(dir.distance, 1e-6);
      target = puck - n * (puckR + paddleR * .6);
      if (puck.dy < top.dy) target = Offset(puck.dx + (puck.dx < .5 ? .1 : -.1), puck.dy - .1);
    } else {
      // Defend: shadow the puck in front of our goal.
      target = Offset(width / 2 + (puck.dx - width / 2) * .6, .14);
    }
    final delta = target - top;
    final step = min(delta.distance, speed * dt);
    final move = delta.distance < 1e-6 ? Offset.zero : delta / delta.distance * step;
    setTop(top + move, dt);
  }

  /// Advances the simulation; returns 0/1 when a side scores.
  int? step(double dt) {
    if (pause > 0) {
      pause -= dt;
      return null;
    }
    const sub = 4;
    for (var i = 0; i < sub; i++) {
      final h = dt / sub;
      puck += puckV * h;
      puckV *= pow(.995, h * 60).toDouble();
      // Side walls.
      if (puck.dx < puckR) {
        puck = Offset(puckR, puck.dy);
        puckV = Offset(-puckV.dx, puckV.dy) * .95;
      } else if (puck.dx > width - puckR) {
        puck = Offset(width - puckR, puck.dy);
        puckV = Offset(-puckV.dx, puckV.dy) * .95;
      }
      final inGoalMouth = (puck.dx - width / 2).abs() < goalWidth / 2;
      if (puck.dy < puckR) {
        if (inGoalMouth) return _goal(0);
        puck = Offset(puck.dx, puckR);
        puckV = Offset(puckV.dx, -puckV.dy) * .95;
      } else if (puck.dy > height - puckR) {
        if (inGoalMouth) return _goal(1);
        puck = Offset(puck.dx, height - puckR);
        puckV = Offset(puckV.dx, -puckV.dy) * .95;
      }
      _collide(bottom, bottomV);
      _collide(top, topV);
    }
    return null;
  }

  int _goal(int scorer) {
    scores[scorer]++;
    lastGoal = scorer;
    faceOff(towardTop: scorer == 1); // puck goes to the side that conceded
    return scorer;
  }

  void _collide(Offset paddle, Offset paddleV) {
    final d = puck - paddle;
    final dist = d.distance;
    const minDist = puckR + paddleR;
    if (dist >= minDist || dist == 0) return;
    final n = d / dist;
    puck = paddle + n * minDist;
    final rel = puckV - paddleV;
    final along = rel.dx * n.dx + rel.dy * n.dy;
    if (along < 0) {
      puckV = puckV - n * (1.9 * along);
    }
    // Paddles always give the puck a little push away.
    puckV += n * .15;
    final s = puckV.distance;
    if (s > maxPuckSpeed) puckV = puckV / s * maxPuckSpeed;
  }
}
