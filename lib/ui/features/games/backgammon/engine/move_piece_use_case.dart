// lib/domain/usecases/move_piece_use_case.dart

import 'constants.dart';

import 'game_entities.dart';

class MovePieceUseCase {
  GameState call({
    required GameState gameState,
    required Move move,
  }) {
    final player = gameState.currentPlayer;

    // Create a new dice list with the used die removed
    final newDice = List<int>.from(gameState.dice);
    newDice.remove(move.die);

    Piece movingPiece;
    List<Point> points = List.from(gameState.points);
    List<Piece> whiteBar = List.from(gameState.whiteBar);
    List<Piece> blackBar = List.from(gameState.blackBar);
    List<Piece> whiteHome = List.from(gameState.whiteHome);
    List<Piece> blackHome = List.from(gameState.blackHome);

    // Remove piece from its origin
    if (move.from == whiteBarIndex) {
      movingPiece = whiteBar.removeLast();
    } else if (move.from == blackBarIndex) {
      movingPiece = blackBar.removeLast();
    } else {
      final originalPoint = points[move.from];
      final piecesOnPoint = List<Piece>.from(originalPoint.pieces);
      movingPiece = piecesOnPoint.removeLast();
      points[move.from] = originalPoint.copyWith(pieces: piecesOnPoint);
    }

    // Add piece to its destination
    final bool isBearOff =
        (move.to == whiteHomeIndex && player == Player.white) ||
            (move.to == blackHomeIndex && player == Player.black);

    if (isBearOff) {
      if (player == Player.white) {
        whiteHome.add(movingPiece);
      } else {
        blackHome.add(movingPiece);
      }
    } else {
      // It's a move to a point
      final destinationPoint = points[move.to];
      final destPieces = List<Piece>.from(destinationPoint.pieces);

      // Check for a hit
      if (destinationPoint.pieceCount == 1 &&
          destinationPoint.player != player) {
        final hitPiece = destPieces.removeLast();
        if (hitPiece.player == Player.white) {
          whiteBar.add(hitPiece);
        } else {
          blackBar.add(hitPiece);
        }
      }

      destPieces.add(movingPiece);
      points[move.to] = destinationPoint.copyWith(pieces: destPieces);
    }

    return gameState.copyWith(
      points: points,
      dice: newDice,
      whiteBar: whiteBar,
      blackBar: blackBar,
      whiteHome: whiteHome,
      blackHome: blackHome,
    );
  }
}
