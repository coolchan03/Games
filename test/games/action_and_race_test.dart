import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/air_hockey/air_hockey_engine.dart';
import 'package:puzzle/ui/features/games/goose_game/goose_game_screen.dart';

void main() {
  group('Air Hockey', () {
    test('puck stays on the table and goals are counted', () {
      final t = AirHockeyPhysics(random: Random(1));
      for (var i = 0; i < 6000; i++) {
        t.aiStep(1 / 60, 2);
        t.setBottom(Offset(.5 + .3 * sin(i / 30), 1.4), 1 / 60);
        t.step(1 / 60);
        expect(t.puck.dx, inInclusiveRange(0, AirHockeyPhysics.width));
        expect(t.puck.dy, inInclusiveRange(-0.1, AirHockeyPhysics.height + 0.1));
      }
      expect(t.scores[0] + t.scores[1], greaterThan(0));
    });
    test('paddles are confined to their halves', () {
      final t = AirHockeyPhysics(random: Random(2));
      t.setBottom(const Offset(.5, .1), 1 / 60);
      expect(t.bottom.dy, greaterThan(AirHockeyPhysics.height / 2));
      t.setTop(const Offset(.5, 1.5), 1 / 60);
      expect(t.top.dy, lessThan(AirHockeyPhysics.height / 2));
    });
  });

  group('Game of the Goose', () {
    test('special squares', () {
      final g = GooseGame(2, random: Random(3));
      g.pos[0] = 2;
      g.firstRoll = false;
      g.roll([1, 3]); // 2 + 4 = 6: bridge to 12
      expect(g.pos[0], 12);
      g.turn = 0;
      g.roll([3, 3]); // 12 + 6 = 18 goose → 24
      expect(g.pos[0], 24);
      g.turn = 0;
      g.pos[0] = 60;
      g.roll([3, 2]); // 65 → bounce to 61
      expect(g.pos[0], 61);
    });
    test('opening 6+3 goes to 26 and bots finish', () {
      final g = GooseGame(4, random: Random(4));
      g.roll([6, 3]);
      expect(g.pos[0], 26);
      var guard = 0;
      while (g.winner == null && guard++ < 5000) {
        g.roll();
      }
      expect(g.winner, isNotNull);
    });
  });
}
