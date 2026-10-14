import 'package:flutter_test/flutter_test.dart';
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
  group('Detective Casebook', () {
    test('each case has a unique consistent solution', () {
      expect(DetectiveCasebook.cases.length, 3);
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
