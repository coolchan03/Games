import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/nim/nim_screen.dart';
import 'package:puzzle/ui/features/games/oware/oware_engine.dart';
import 'package:puzzle/ui/features/games/war/war_screen.dart';

void main() {
  group('Oware', () {
    test('48 seeds are conserved and captures happen', () {
      final s = OwareState();
      final rng = Random(1);
      var guard = 0;
      while (s.result == -1 && guard++ < 500) {
        s.play(owareAi(s, 1, rng));
        expect(s.pits.fold<int>(0, (a, b) => a + b) + s.stores[0] + s.stores[1], 48);
      }
      expect(s.result, isNot(-1));
    });
    test('must feed an empty opponent', () {
      final s = OwareState();
      s.pits.fillRange(0, 12, 0);
      s.pits[5] = 1; // only move reaches the opponent
      s.pits[0] = 1;
      expect(s.legalMoves(), [5]);
    });
    test('grand slam captures nothing', () {
      final s = OwareState();
      s.pits.fillRange(0, 12, 0);
      s.pits[5] = 1;
      s.pits[6] = 2; // sowing makes 3: would capture every opponent seed
      s.play(5);
      expect(s.stores[0], 0);
      expect(s.pits[6], 3);
    });
  });

  group('Nim', () {
    test('perfect play wins from a winning position', () {
      for (final misere in [false, true]) {
        final g = NimGame([1, 3, 5], misere: misere);
        final rng = Random(2);
        while (!g.over) {
          final (r, n) = g.bestMove(rng, 2);
          g.take(r, n);
        }
        // Normal play: nim-sum 1^3^5 = 7 ≠ 0 so the first player wins.
        if (!misere) expect(g.winner, 0);
      }
    });
  });

  group('War', () {
    test('cards are conserved during play', () {
      final g = WarGame(random: Random(3));
      for (var i = 0; i < 200 && g.winner == null; i++) {
        g.flip();
        if (g.winner == null) expect(g.hands[0].length + g.hands[1].length, 52);
      }
    });
  });
}
