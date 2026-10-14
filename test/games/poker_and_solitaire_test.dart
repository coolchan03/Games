import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/common/poker_eval.dart';
import 'package:puzzle/ui/features/games/freecell/freecell_engine.dart';
import 'package:puzzle/ui/features/games/golf_solitaire/golf_engine.dart';
import 'package:puzzle/ui/features/games/klondike/klondike_engine.dart';
import 'package:puzzle/ui/features/games/pyramid/pyramid_engine.dart';
import 'package:puzzle/ui/features/games/spider/spider_engine.dart';
import 'package:puzzle/ui/features/games/texas_holdem/holdem_engine.dart';
import 'package:puzzle/ui/features/games/video_poker/video_poker_engine.dart';

List<PlayingCard> cards(String s) => PlayingCard.cardsFromString(s);

void main() {
  group('Poker evaluator', () {
    test('categories', () {
      expect(rankFive(cards('AS KS QS JS TS')).label, 'Royal flush');
      expect(rankFive(cards('5H 4H 3H 2H AH')).category, HandCategory.straightFlush);
      expect(rankFive(cards('9C 9D 9H 9S 2C')).category, HandCategory.fourOfAKind);
      expect(rankFive(cards('3C 3D 3H 2S 2C')).category, HandCategory.fullHouse);
      expect(rankFive(cards('2D 7D 9D JD KD')).category, HandCategory.flush);
      expect(rankFive(cards('5C 4D 3H 2S AC')).category, HandCategory.straight);
      expect(rankFive(cards('7C 7D 7H KS 2C')).category, HandCategory.threeOfAKind);
      expect(rankFive(cards('7C 7D 2H 2S KC')).category, HandCategory.twoPair);
      expect(rankFive(cards('7C 7D 3H 2S KC')).category, HandCategory.pair);
      expect(rankFive(cards('7C 9D 3H 2S KC')).category, HandCategory.highCard);
    });
    test('wheel loses to six-high straight, kickers decide pairs', () {
      expect(rankFive(cards('6C 5D 4H 3S 2C')) > rankFive(cards('5C 4D 3H 2S AC')), isTrue);
      expect(rankFive(cards('AC AD KH 3S 2C')) > rankFive(cards('AH AS QH JS TC')), isTrue);
      expect(rankFive(cards('AC AD KH 3S 2C')).value, rankFive(cards('AH AS KD 3C 2D')).value);
    });
    test('best of seven', () {
      final r = bestHand(cards('AS KS 2D 3C QS JS TS'));
      expect(r.label, 'Royal flush');
    });
  });

  group("Texas Hold'em", () {
    test('blinds are posted and chips are conserved through a hand', () {
      final g = HoldemGame(names: ['A', 'B', 'C', 'D'], random: Random(1));
      g.startHand();
      expect(g.pot, 30);
      var guard = 0;
      while (!g.handOver && guard++ < 200) {
        g.act(g.botAction(g.current, 1));
      }
      expect(g.handOver, isTrue);
      expect(g.players.fold<int>(0, (s, p) => s + p.chips), 4000);
    });
    test('many random hands with all-ins never lose chips', () {
      final rng = Random(5);
      final g = HoldemGame(names: ['A', 'B', 'C', 'D'], random: rng);
      for (var hand = 0; hand < 60 && !g.matchOver; hand++) {
        g.startHand();
        var guard = 0;
        while (!g.handOver && guard++ < 300) {
          final roll = rng.nextInt(10);
          final seat = g.current;
          if (roll < 2 && g.canRaise(seat)) {
            g.act(PokerAction(ActionType.raise, g.maxRaiseTo(seat)));
          } else if (roll < 3) {
            g.act(const PokerAction(ActionType.fold));
          } else {
            g.act(const PokerAction(ActionType.call));
          }
        }
        expect(g.handOver, isTrue);
        expect(g.players.fold<int>(0, (s, p) => s + p.chips), 4000);
      }
    });
    test('side pot goes to the right player', () {
      final g = HoldemGame(names: ['A', 'B', 'C'], random: Random(2));
      g.players[0].chips = 100;
      g.startHand();
      // Everyone goes all-in.
      var guard = 0;
      while (!g.handOver && guard++ < 20) {
        final s = g.current;
        if (g.canRaise(s)) {
          g.act(PokerAction(ActionType.raise, g.maxRaiseTo(s)));
        } else {
          g.act(const PokerAction(ActionType.call));
        }
      }
      expect(g.board.length, 5);
      expect(g.players.fold<int>(0, (s, p) => s + p.chips), 2100);
      // Player A can win at most 3 * 100 = 300.
      expect(g.players[0].chips, lessThanOrEqualTo(300));
    });
  });

  group('Video poker', () {
    test('pay table', () {
      expect(payoutName(cards('JC JD 3H 4S 9C')), 'Jacks or better');
      expect(payoutName(cards('TC TD 3H 4S 9C')), isNull);
      expect(payout(cards('AS KS QS JS TS'), 5), 4000);
      expect(payout(cards('AS KS QS JS TS'), 1), 800);
    });
    test('advice keeps a made royal flush', () {
      final g = VideoPokerGame(random: Random(3));
      g.deal();
      g.hand = cards('AS KS QS JS TS');
      expect(g.bestHold(samples: 20), [true, true, true, true, true]);
    });
  });

  group('Klondike', () {
    test('deal has 28 tableau cards and 24 in stock', () {
      final g = KlondikeGame(random: Random(1));
      expect(g.tableau.fold<int>(0, (s, t) => s + t.length), 28);
      expect(g.stock.length, 24);
      expect(g.tableau.every((t) => t.last.up), isTrue);
    });
    test('drawing cycles the stock and undo restores it', () {
      final g = KlondikeGame(drawThree: true, random: Random(1));
      for (var i = 0; i < 8; i++) {
        g.drawStock();
      }
      expect(g.stock, isEmpty);
      expect(g.waste.length, 24);
      g.drawStock();
      expect(g.stock.length, 24);
      g.undo();
      expect(g.waste.length, 24);
    });
  });

  group('FreeCell', () {
    test('Microsoft deal #1 matches the classic layout', () {
      final d = microsoftDeal(1);
      expect(PlayingCard.stringFromCards(d.take(8)), 'JD 2D 9H JC 5D 7H 7C 5H');
    });
    test('supermove capacity', () {
      final g = FreeCellGame(1);
      expect(g.maxRun(toEmpty: false), 5);
    });
  });

  group('Spider, Golf, Pyramid', () {
    test('spider deals 54 + 50 and dealing adds a row', () {
      final g = SpiderGame(suits: 2, random: Random(4));
      expect(g.tableau.fold<int>(0, (s, t) => s + t.length), 54);
      expect(g.stock.length, 50);
      expect(g.deal(), isTrue);
      expect(g.stock.length, 40);
    });
    test('golf plays only adjacent ranks', () {
      final g = GolfGame(random: Random(6));
      for (var c = 0; c < 7; c++) {
        final d = (aceLowRank(g.columns[c].last) - aceLowRank(g.waste.last)).abs();
        expect(g.canPlay(c), d == 1 && aceLowRank(g.waste.last) != 13);
      }
    });
    test('pyramid pairs must sum to 13', () {
      final g = PyramidGame(random: Random(8));
      expect(g.exposed(6, 0), isTrue);
      expect(g.exposed(0, 0), isFalse);
      final bottom = [for (var c = 0; c < 7; c++) PyramidGame.indexOf(6, c)];
      for (final a in bottom) {
        for (final b in bottom) {
          if (a == b) continue;
          final sum = aceLowRank(g.pyramid[a]!) + aceLowRank(g.pyramid[b]!);
          final copy = PyramidGame(random: Random(8));
          expect(copy.remove(a, b), sum == 13);
        }
      }
    });
  });
}

int aceLowRank(PlayingCard c) => c.rank == Rank.ace ? 1 : c.rank.numericValue;
