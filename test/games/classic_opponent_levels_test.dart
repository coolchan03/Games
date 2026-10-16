import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/bagh_bandi/bagh_bandi_engine.dart';
import 'package:puzzle/ui/features/games/passe_trappe/passe_trappe_engine.dart';

void main() {
  test('Passe-Trappe offers three genuinely different launch strengths', () {
    final speeds = <double>[];
    for (var level = 0; level < 3; level++) {
      final game = PasseTrappeGame();
      expect(game.autoLaunch(Random(12), side: 1, level: level), true);
      expect(game.countOnSide(1), 5);
      final puck = game.pucks.singleWhere((p) => p.velocity.distance > 0.01);
      speeds.add(puck.velocity.distance);
      expect(puck.position.dy, lessThan(.5));
    }
    expect(speeds[0], lessThan(speeds[1]), reason: 'Easy is slower');
    expect(speeds[1], lessThan(speeds[2]), reason: 'Hard is faster');
  });

  test('Passe-Trappe allows finger-sized touch selection', () {
    final game = PasseTrappeGame();
    final puck = game.pucks.firstWhere((p) => p.position.dy > .5);
    final point = puck.position + const Offset(0, .09);
    expect(game.puckAt(point, side: 0)?.id, puck.id);
  });

  test('Bagh Bandi easy/medium/hard all choose legal moves without mutation', () {
    for (var level = 0; level < 3; level++) {
      final game = BaghBandiGame();
      final original = game.toJson();
      final move = game.chooseMove(Random(42), level: level);
      expect(game.legalMoves, contains(move));
      expect(game.toJson(), original);
      expect(game.move(move), isTrue);
      expect(game.turn, BandiSide.tigers);
      final answer = game.chooseMove(Random(42), level: level);
      expect(game.legalMoves, contains(answer));
    }
  });
}
