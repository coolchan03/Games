import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/dominoes/dominoes_engine.dart';
import 'package:puzzle/ui/features/games/go_game/go_engine.dart';
import 'package:puzzle/ui/features/games/hex/hex_engine.dart';
import 'package:puzzle/ui/features/games/liars_dice/liars_dice_engine.dart';

void main() {
  group('Hex', () {
    test('a straight column connects top to bottom', () {
      final g = HexGame(n: 5);
      for (var y = 0; y < 5; y++) {
        g.cells[y * 5 + 2] = 1;
      }
      expect(g.connected(g.cells, 1), isTrue);
      expect(g.connected(g.cells, 2), isFalse);
    });
    test('computer blocks an immediate win and full games end', () {
      final g = HexGame(n: 5);
      for (var y = 0; y < 4; y++) {
        g.cells[y * 5 + 2] = 1;
      }
      g.history.add(2);
      g.turn = 2;
      // Both (2,4) and (1,4) would complete Red's column; Blue must take one.
      expect([4 * 5 + 1, 4 * 5 + 2], contains(g.aiMove(50, Random(1))));
      final h = HexGame(n: 7);
      final rng = Random(2);
      while (h.winner == 0) {
        h.play(h.aiMove(30, rng));
      }
      expect(h.winner, isNot(0));
    });
  });

  group('Go', () {
    test('capture and suicide rules', () {
      final b = GoBoard(5);
      // Black surrounds a white stone at (1,1) = 6.
      for (final m in [1, 6, 5, 24, 7, 23]) {
        expect(b.play(m), isTrue);
      }
      // White at 6 has one liberty (11); black plays 11 to capture.
      expect(b.play(11), isTrue);
      expect(b.cells[6], 0);
      expect(b.captures[0], 1);
      // White playing into 6 now is suicide (surrounded, captures nothing).
      expect(b.isLegal(6), isFalse);
    });
    test('ko forbids immediate recapture', () {
      final k = GoBoard(4);
      k.cells.setAll(0, [0, 1, 2, 0, 1, 0, 1, 2, 0, 1, 2, 0, 0, 0, 0, 0]);
      k.turn = 2;
      expect(k.play(5), isTrue); // white captures black at 6
      expect(k.cells[6], 0);
      expect(k.isLegal(6), isFalse, reason: 'black may not retake the ko at once');
    });
    test('area scoring counts territory', () {
      final b = GoBoard(5);
      for (var y = 0; y < 5; y++) {
        b.cells[y * 5 + 2] = 1;
      }
      final (black, white) = b.score(0.5);
      expect(black, 25);
      expect(white, 0.5);
    });
    test('computer move is legal', () {
      final b = GoBoard(9);
      final m = b.aiMove(40, Random(3), 6.5, timeMs: 2000);
      expect(m == -1 || b.isLegal(m), isTrue);
    });
  });

  group("Liar's Dice", () {
    test('probabilities', () {
      expect(LiarsDiceGame.atLeast(0, 0, 10), 1);
      expect(LiarsDiceGame.atLeast(11, 0, 10), 0);
      expect(LiarsDiceGame.atLeast(1, 0, 1), closeTo(1 / 3, 1e-9));
    });
    test('bids must rise and a bot game finishes', () {
      final g = LiarsDiceGame(players: 3, random: Random(4));
      g.makeBid(3, 4);
      expect(g.validBid(3, 4), isFalse);
      expect(g.validBid(3, 5), isTrue);
      expect(g.validBid(2, 6), isFalse);
      var guard = 0;
      while (g.winner == null && guard++ < 5000) {
        final d = g.aiDecide(2);
        if (d == null && g.bid != null) {
          g.nextRound(g.challenge());
        } else if (d != null) {
          g.makeBid(d.$1, d.$2);
        } else {
          g.makeBid(1, 2);
        }
      }
      expect(g.winner, isNotNull);
    });
  });

  group('Dominoes', () {
    test('28 tiles in play and chain ends match', () {
      final g = DominoesGame(players: 2, random: Random(5));
      final total = g.hands.fold<int>(0, (s, h) => s + h.length) + g.boneyard.length;
      expect(total, 28);
      var guard = 0;
      while (g.roundWinner == null && guard++ < 500) {
        g.aiTurn(2);
        for (var i = 0; i + 1 < g.line.length; i++) {
          expect(g.line[i].right, g.line[i + 1].left);
        }
      }
      expect(g.roundWinner, isNotNull);
      expect(g.scores.reduce(max), greaterThanOrEqualTo(0));
    });
  });
}
