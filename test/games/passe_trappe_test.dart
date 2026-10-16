import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/passe_trappe/passe_trappe_engine.dart';

void main() {
  test('starts 5 pucks per half, IDs unique, no score yet', () {
    final game = PasseTrappeGame();
    expect(game.pucks.length, 10);
    expect(game.pucks.map((p) => p.id).toSet().length, 10);
    expect(game.countOnSide(0), 5);
    expect(game.countOnSide(1), 5);
    expect(game.winner, isNull);
  });

  test('dragging back from bottom shoots forward; invalid pull ignored', () {
    final game = PasseTrappeGame();
    final id = game.pucks.firstWhere((p) => p.position.dy > .5).id;
    expect(game.launch(id, const Offset(0, -.16)), isFalse);
    expect(game.launch(id, const Offset(0, .18)), isTrue);
    expect(game.pucks.firstWhere((p) => p.id == id).velocity.dy, lessThan(0));
    expect(game.launch(id, const Offset(0, .16)), isFalse);
  });

  test('central divider only allows crossing through the gate', () {
    final game = PasseTrappeGame();
    final puck = game.pucks.firstWhere((p) => p.position.dy > .5);
    puck.position = const Offset(.15, .56);
    puck.velocity = const Offset(0, -1.8);
    game.step(.04);
    expect(game.countOnSide(0), 5);
    expect(puck.position.dy, greaterThan(.5));
    expect(puck.velocity.dy, greaterThanOrEqualTo(0));
    puck.position = const Offset(.5, .56);
    puck.velocity = const Offset(0, -1.8);
    game.step(.08);
    expect(game.countOnSide(0), 4);
    expect(game.countOnSide(1), 6);
  });

  test('physics conserves ten pucks, contains all and handles ricochets', () {
    final game = PasseTrappeGame();
    final rng = Random(8);
    for (var n = 0; n < 240; n++) {
      if (n % 30 == 0) game.autoLaunch(rng, side: 1, level: 1);
      game.step(1 / 60);
    }
    expect(game.pucks.length, 10);
    for (final puck in game.pucks) {
      expect(puck.position.dx, inInclusiveRange(0.0, 1.0));
      expect(puck.position.dy, inInclusiveRange(0.0, 1.6));
      expect(puck.velocity.dx.isFinite, isTrue);
      expect(puck.velocity.dy.isFinite, isTrue);
    }
  });

  test('clearing a half wins and save data rejects tampering', () {
    final game = PasseTrappeGame();
    final saved = game.toJson();
    expect(PasseTrappeGame.fromJson(saved).toJson(), saved);
    final broken = Map<String, dynamic>.from(saved);
    broken['pucks'] = [saved['pucks'][0], saved['pucks'][0]];
    expect(() => PasseTrappeGame.fromJson(broken), throwsFormatException);
    for (final puck in game.pucks) {
      puck.position = Offset(puck.position.dx, .22);
    }
    expect(game.winner, 0);
  });

  test('computer only shoots available idle pucks on its half', () {
    final game = PasseTrappeGame();
    final rng = Random(9);
    expect(game.autoLaunch(rng, side: 1, level: 2), isTrue);
    expect(game.pucks.where((p) => p.velocity.distance > .01).single.position.dy,
        lessThan(.5));
  });
}
