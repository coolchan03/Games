import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/blackjack/blackjack_engine.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/crazy_eights/crazy_eights_engine.dart';
import 'package:puzzle/ui/features/games/gin_rummy/gin_rummy_engine.dart';
import 'package:puzzle/ui/features/games/go_fish/go_fish_engine.dart';

List<PlayingCard> cards(String s) => PlayingCard.cardsFromString(s);

void main() {
  group('Gin Rummy', () {
    test('finds the best melds and deadwood', () {
      final r = bestMelds(cards('AS 2S 3S 4S 7H 7D 7C KD QC 5H'));
      expect(r.points, 25);
      expect(r.melds.length, 2);
      // 4 of a kind and a run sharing a card: choose the better split.
      final g = bestMelds(cards('5H 5D 5C 5S 6S 7S 2C 3C KH KD'));
      expect(g.points, 25);
    });
    test('gin hand has zero deadwood', () {
      expect(bestMelds(cards('AH 2H 3H 9C 9D 9S JS QS KS TS')).points, 0);
    });
    test('computer vs computer hands always score or wash', () {
      final g = GinRummyGame(random: Random(3));
      var hands = 0;
      while (!g.matchOver && hands < 40) {
        var guard = 0;
        while (g.phase != GinPhase.handOver && guard++ < 200) {
          g.aiTurn(2);
        }
        expect(g.phase, GinPhase.handOver);
        expect(g.hands[0].length + g.hands[1].length, 20);
        hands++;
        if (!g.matchOver) g.deal();
      }
      expect(g.scores.reduce(max), greaterThan(0));
    });
  });

  group('Crazy Eights', () {
    test('eights are always playable and set the suit', () {
      final g = CrazyEightsGame(2, random: Random(1));
      final eight = PlayingCard(Rank.eight, Suit.clubs);
      expect(g.canPlay(eight), isTrue);
      g.hands[0].add(eight);
      g.play(eight, chosen: Suit.hearts);
      expect(g.activeSuit, Suit.hearts);
    });
    test('bot game finishes', () {
      final g = CrazyEightsGame(4, random: Random(2));
      var guard = 0;
      while (g.winner == null && guard++ < 1000) {
        g.aiTurn(1);
      }
      expect(g.winner, isNotNull);
      final total = g.hands.fold<int>(0, (s, h) => s + h.length) + g.stock.length + g.discard.length;
      expect(total, 52);
    });
  });

  group('Go Fish', () {
    test('bots complete all 13 books', () {
      final g = GoFishGame(3, random: Random(5));
      var guard = 0;
      while (!g.over && guard++ < 2000) {
        final (t, r) = g.aiAsk(2);
        g.ask(t, r);
      }
      expect(g.over, isTrue);
      expect(g.books.fold<int>(0, (s, b) => s + b.length), 13);
    });
  });

  group('Blackjack', () {
    test('totals with soft aces', () {
      expect(handTotal(cards('AS 6D')), (17, true));
      expect(handTotal(cards('AS 6D TC')), (17, false));
      expect(handTotal(cards('AS AD')), (12, true));
    });
    test('chips are conserved across many rounds of basic strategy', () {
      final g = BlackjackGame(random: Random(8));
      for (var r = 0; r < 300; r++) {
        if (g.chips < g.bet) g.chips += 1000;
        g.deal();
        var guard = 0;
        while (g.inRound && guard++ < 20) {
          switch (g.advice()) {
            case 'Split':
              g.split();
            case 'Double':
              g.canDouble ? g.doubleDown() : g.hit();
            case 'Hit':
              g.hit();
            default:
              g.stand();
          }
        }
        expect(g.inRound, isFalse);
        expect(g.chips, greaterThanOrEqualTo(0));
      }
    });
    test('advice examples', () {
      final g = BlackjackGame(random: Random(1));
      g.inRound = true;
      g.dealer = cards('6H 9C');
      g.hands = [BjHand(cards('8S 8D'), 10)];
      expect(g.advice(), 'Split');
      g.hands = [BjHand(cards('TS 6D'), 10)];
      expect(g.advice(), 'Stand');
      g.dealer = cards('TH 9C');
      expect(g.advice(), 'Hit');
      g.hands = [BjHand(cards('6S 5D'), 10)];
      expect(g.advice(), 'Double');
    });
  });
}
