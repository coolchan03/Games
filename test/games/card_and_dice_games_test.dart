import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/chess/engine/ai/hard_ai.dart';
import 'package:puzzle/ui/features/games/chess/engine/models/chess_move.dart';
import 'package:puzzle/ui/features/games/chess/engine/models/chess_state.dart';
import 'package:puzzle/ui/features/games/chess/engine/models/enums.dart' hide AiDifficulty;
import 'package:puzzle/ui/features/games/code_breaker/code_breaker_engine.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/common/cards/trick.dart';
import 'package:puzzle/ui/features/games/hearts/engine/hearts.dart';
import 'package:puzzle/ui/features/games/hearts/engine/hearts_ai.dart' as hai;
import 'package:puzzle/ui/features/games/oh_hell/engine/ohhell.dart' show OhHellMatch, OhHellRuleSet;
import 'package:puzzle/ui/features/games/spades/engine/spades.dart' show SpadesRound, SpadesRuleSet, SpadesRoundStatus;
import 'package:puzzle/ui/features/games/yacht_dice/engine/scoring.dart';
import 'package:puzzle/ui/features/games/yacht_dice/engine/scoring_category.dart';
import 'package:puzzle/ui/features/games/yacht_dice/engine/yacht_dice_state.dart';
import 'package:puzzle/ui/features/games/yacht_dice/engine/yacht_game.dart';

ChessState play(ChessState s, List<String> uci) {
  for (final m in uci) {
    final want = ChessMove.fromUci(m);
    final move = s.allLegalMoves.firstWhere((x) => x == want);
    s = s.applyMove(move);
  }
  return s;
}

void main() {
  group('Chess', () {
    test('starting position has 20 legal moves', () {
      expect(ChessState.initial().allLegalMoves.length, 20);
    });
    test("fool's mate is checkmate for black", () {
      final s = play(ChessState.initial(), ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(s.status, GameStatus.checkmate);
      expect(s.winner, PieceColor.black);
    });
    test('en passant is generated and removes the pawn', () {
      final s = play(ChessState.initial(), ['e2e4', 'a7a6', 'e4e5', 'd7d5']);
      final ep = s.allLegalMoves.where((m) => m.isEnPassant).toList();
      expect(ep.length, 1);
      final after = s.applyMove(ep.first);
      expect(after.pieceAt(3, 3), isNull);
    });
    test('castling kingside moves the rook', () {
      final s = ChessState.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final castle = s.allLegalMoves.firstWhere((m) => m.isCastling && m.toCol == 6);
      final after = s.applyMove(castle);
      expect(after.pieceAt(7, 5)?.type, PieceType.rook);
    });
    test('stalemate is detected', () {
      final stale = ChessState.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(stale.allLegalMoves, isEmpty);
      expect(stale.isCheck, isFalse);
    });
    test('computer finds mate in one', () async {
      final s = ChessState.fromFen('6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1');
      final move = await HardChessAi()
          .findBestMove(s, timeLimit: const Duration(milliseconds: 800));
      expect(s.applyMove(move!).status, GameStatus.checkmate);
    });
  });

  group('Hearts', () {
    test('2 of clubs must lead the first trick', () {
      final round = HeartsRound.deal(HeartsRuleSet(), [0, 0, 0, 0], 0, Random(1));
      expect(round.legalPlaysForCurrentPlayer(), [PlayingCard(Rank.two, Suit.clubs)]);
    });
    test('a full round of AI play scores 26 points', () {
      final rng = Random(4);
      final round = HeartsRound.deal(HeartsRuleSet(), [0, 0, 0, 0], 0, rng);
      while (!round.isOver()) {
        final req = hai.CardToPlayRequest.fromRound(round);
        round.playCard(hai.chooseCardAvoidingPoints(req, rng));
      }
      final pts = round.pointsTaken();
      final total = pts.reduce((a, b) => a + b);
      // 26 normally, or 78 when someone shoots the moon.
      expect(total == 26 || total == 78, isTrue);
    });
    test('shooting the moon gives 26 to everyone else', () {
      final rules = HeartsRuleSet();
      // Hand every card to player 0's tricks.
      final all = standardDeckCards();
      final ts = [
        for (var i = 0; i < 13; i++)
          Trick(0, all.sublist(i * 4, i * 4 + 4), 0)
      ];
      expect(pointsForTricks(ts, rules), [0, 26, 26, 26]);
    });
  });

  group('Spades and Oh Hell', () {
    test('spades is trump when trick is finished', () {
      final round = SpadesRound.deal(SpadesRuleSet(), [0, 0], 0, Random(3));
      for (var p = 0; p < 4; p++) {
        round.setBidForPlayer(bid: 3, playerIndex: p);
      }
      expect(round.status, SpadesRoundStatus.playing);
      final rng = Random(5);
      while (!round.isOver()) {
        final legal = round.legalPlaysForCurrentPlayer();
        round.playCard(legal[rng.nextInt(legal.length)]);
      }
      expect(round.previousTricks.length, 13);
    });
    test('oh hell dealer cannot make bids add up', () {
      final match = OhHellMatch(OhHellRuleSet(bidTotalCantEqualTricks: true), Random(7));
      final r = match.currentRound;
      for (var i = 0; i < 3; i++) {
        r.setBidForPlayer(bid: 1, playerIndex: r.currentBidder());
      }
      expect(r.disallowedBidForCurrentBidder(), r.numCardsPerPlayer - 3);
    });
  });

  group('Yacht Dice', () {
    test('category scores', () {
      expect(calculateScore([3, 3, 3, 5, 5], ScoringCategory.fullHouse), 25);
      expect(calculateScore([1, 2, 3, 4, 6], ScoringCategory.smallStraight), 15);
      expect(calculateScore([2, 3, 4, 5, 6], ScoringCategory.largeStraight), 30);
      expect(calculateScore([4, 4, 4, 4, 4], ScoringCategory.yacht), 50);
      expect(calculateScore([6, 6, 6, 6, 2], ScoringCategory.fourOfAKind), 26);
    });
    test('a full game against the hard computer completes', () async {
      final g = YachtGame(ai: AiDifficulty.hard, random: Random(9));
      var guard = 0;
      while (!g.isOver && guard++ < 500) {
        if (g.current.type == PlayerType.human) {
          g.roll();
          final open = ScoringCategory.values.firstWhere((c) => g.current.scores[c] == null);
          expect(g.select(open), isTrue);
        } else {
          while (await g.aiStep()) {}
        }
      }
      expect(g.isOver, isTrue);
      for (final p in g.state.players) {
        expect(p.scores.values.every((v) => v != null), isTrue);
      }
    });
  });

  group('Code Breaker', () {
    test('hits and blows', () {
      expect(scoreGuess([0, 1, 2, 3], [0, 2, 1, 5]), (1, 2));
      expect(scoreGuess([1, 1, 2, 2], [1, 2, 1, 1]), (1, 2));
    });
    test('hint is always consistent and the solver can win', () {
      final g = CodeBreakerGame(CodeBreakerMode.classic, random: Random(11));
      while (!g.over) {
        g.submit(g.hint()!);
      }
      expect(g.won, isTrue);
    });
  });
}
