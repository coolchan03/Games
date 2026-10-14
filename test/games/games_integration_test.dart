import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/mahjong_board.dart';
import 'package:puzzle/ui/features/games/checkers/engine/checkers_rules.dart';
import 'package:puzzle/ui/features/games/reversi/engine/game_board.dart';
import 'package:puzzle/ui/features/games/mancala/engine/mancala_state.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_engine.dart';

void main() {
  group('Reversi', () {
    test('opening move flips one opponent piece', () {
      final board = GameBoard();
      final moves = board.getMovesForPlayer(PieceType.black);
      expect(moves.length, 4);
      final after = board.updateForMove(moves.first.x, moves.first.y, PieceType.black);
      expect(after.getPieceCount(PieceType.black), 4);
      expect(after.getPieceCount(PieceType.white), 1);
      expect(board.getPieceCount(PieceType.black), 2);
    });
    test('occupied squares are illegal', () {
      expect(GameBoard().isLegalMove(3, 3, PieceType.black), false);
    });
  });
  group('Mancala', () {
    test('initial position has 48 seeds', () {
      expect(MancalaState.newGame().board.fold<int>(0, (a, b) => a + b), 48);
    });
    test('landing in store grants extra turn', () {
      final result = MancalaState.newGame().sowSeeds(2);
      expect(result.landedInStore, true);
      expect(result.newState.currentPlayer, 0);
      expect(result.newState.board[6], 1);
      expect(result.newState.board.fold<int>(0, (a, b) => a + b), 48);
    });
  });
  group('Checkers', () {
    test('the opening has seven legal white moves', () {
      final position = CheckersPosition.start();
      expect(position.turn, 1);
      expect(position.legalMoves.length, 7);
      expect(position.legalMoves.every((m) => !m.isCapture), true);
    });
    test('captures are mandatory and chained jumps remove two pieces', () {
      final cells = List<int>.filled(64, 0);
      cells[5 * 8 + 1] = 1;
      cells[4 * 8 + 2] = 2;
      cells[2 * 8 + 4] = 2;
      final position = CheckersPosition(cells, 1);
      final jumps = position.legalMoves;
      expect(jumps.length, 1);
      expect(jumps.first.isCapture, true);
      expect(jumps.first.captured.length, 2);
      final after = position.play(jumps.first);
      expect(after.cells.where((v) => v == 2).length, 0);
      expect(after.turn, 2);
    });
    test('men promote to kings on the back rank', () {
      final cells = List<int>.filled(64, 0);
      cells[1 * 8 + 2] = 1;
      final position = CheckersPosition(cells, 1);
      final promoted = position.play(
        position.legalMoves.firstWhere((m) => m.to ~/ 8 == 0));
      expect(promoted.cells.any((p) => p == 3), true);
    });
  });
  group('Mahjong Solitaire', () {
    test('64 tiles have a complete legal solution by construction', () {
      final board = MahjongBoard.generate(Random(42));
      expect(board.remaining, 64);
      for (final pair in board.solutionOrder) {
        expect(board.isFree(pair.first), true);
        expect(board.isFree(pair.second), true);
        expect(board.remove(pair.first, pair.second), true);
      }
      expect(board.complete, true);
      board.undo();
      expect(board.remaining, 2);
      expect(board.matches, isNotEmpty);
    });
    test('different seeds produce independently solvable boards', () {
      for (final seed in [1, 2, 3, 4, 5, 1234, 9876]) {
        final board = MahjongBoard.generate(Random(seed));
        for (final pair in board.solutionOrder) {
          expect(board.remove(pair.first, pair.second), true, reason: '$seed');
        }
        expect(board.complete, true, reason: '$seed');
      }
    });
  });
  group('Detective Casebook', () {
    test('each case has a unique consistent solution', () {
      expect(DetectiveCasebook.cases.length, 9);
      for (final game in DetectiveCasebook.cases) {
        expect(game.countSolutions(), 1, reason: game.title);
        expect(game.clues.every((clue) => clue.matches(game.solution)), true,
            reason: game.title);
        expect(game.accuse(game.culprit), true);
        expect(game.suspects.where(game.accuse).length, 1);
      }
    });
  });
}
