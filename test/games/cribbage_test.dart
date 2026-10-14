import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/cribbage/cribbage_engine.dart';

List<PlayingCard> c(String s) => PlayingCard.cardsFromString(s);

void main() {
  test('show scoring', () {
    // The perfect 29 hand.
    expect(scoreShow(c('5H 5D 5C JS'), c('5S').first), 29);
    // Run 2-3-4 (3) plus fifteens 2+3+K and 2+4+9 (4).
    expect(scoreShow(c('2H 3D 4C 9S'), c('KH').first), 7);
    // Double run 3-4-4-5 (6), pair of fours (2) and 5+K fifteen (2).
    expect(scoreShow(c('3H 4D 4C 5S'), c('KH').first), 10);

    // Run of four (4), flush (4), fifteens 4+5+6 and 5+K (4).
    expect(scoreShow(c('4H 5H 6H 7H'), c('KC').first), 12);
    // A crib only scores a five-card flush.
    expect(scoreShow(c('4H 5H 6H 7H'), c('KC').first, crib: true), 8);
    expect(scoreShow(c('JD 2C 7H 9S'), c('3D').first), 3); // nobs (1) and J+2+3 fifteen (2)
  });

  test('pegging scoring', () {
    expect(peggingScore(c('7H 8C')), 2); // fifteen
    expect(peggingScore(c('5H 5C')), 2); // pair
    expect(peggingScore(c('5H 5C 5D')), 6 + 2); // pair royal and fifteen
    expect(peggingScore(c('3H 5C 4D')), 3); // run in any order
    expect(peggingScore(c('TH 6C 5D 5S 5C')), 2 + 6); // 31 and a pair royal
  });

  test('illegal discards and pegging cards cannot create phantom cards', () {
    final g = CribbageGame(random: Random(42));
    final held = g.hands[0].first;
    final fake = standardDeckCards().firstWhere((x) => !g.hands[0].contains(x));
    g.discard([held, fake], 1);
    expect(g.phase, CribPhase.discard);
    expect(g.hands[0].length, 6);
    g.discard([held, held], 1);
    expect(g.phase, CribPhase.discard);
    g.discard(g.hands[0].take(2).toList(), 1);
    expect(g.phase, CribPhase.pegging);
    final bogus = standardDeckCards().firstWhere(
        (x) => !g.pegHands[g.turn].contains(x));
    final count = g.count;
    final original = g.pegHands[g.turn].length;
    g.play(bogus);
    expect(g.count, count);
    expect(g.pegHands[g.turn].length, original);
  });

  test('computer vs computer games reach 121', () {
    final rng = Random(4);
    for (var game = 0; game < 3; game++) {
      final g = CribbageGame(random: rng);
      var guard = 0;
      while (g.phase != CribPhase.gameOver && guard++ < 2000) {
        switch (g.phase) {
          case CribPhase.discard:
            g.discard(g.aiDiscard(g.hands[0], g.dealer == 0, 2), 2);
          case CribPhase.pegging:
            g.play(g.aiPeg(1));
          case CribPhase.show:
            g.nextHand();
          case CribPhase.gameOver:
            break;
        }
      }
      expect(g.phase, CribPhase.gameOver);
      expect(g.winner, isNotNull);
    }
  });
}
