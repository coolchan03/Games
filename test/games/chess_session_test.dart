import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/chess/chess_session.dart';

void main() {
  test('opening has twenty legal moves and rejects illegal pawn jump', () {
    final game = ChessSession();
    expect(game.legalMoves.length, 20);
    expect(game.play('e2', 'e5'), false);
    expect(game.play('e2', 'e4'), true);
    game.undo();
    expect(game.legalMoves.length, 20);
  });
  test('fools mate ends play', () {
    final game = ChessSession();
    for (final move in ['f3', 'e5', 'g4', 'Qh4#']) { expect(game.playSan(move), true); }
    expect(game.position.in_checkmate, true);
    expect(game.playSan('a3'), false);
    expect(game.status, contains('Black wins'));
  });
  test('castling moves rook and king', () {
    final game = ChessSession(fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    expect(game.play('e1', 'g1'), true);
    expect(game.position.get('f1')?.type.name, 'r');
    expect(game.position.get('h1'), isNull);
  });
  test('en passant removes passed pawn', () {
    final game = ChessSession();
    for (final move in ['e4', 'a6', 'e5', 'd5', 'exd6']) { expect(game.playSan(move), true); }
    expect(game.position.get('d5'), isNull);
    expect(game.position.get('d6')?.type.name, 'p');
  });
  test('underpromotion is supported', () {
    final game = ChessSession(fen: '7k/P7/8/8/8/8/8/7K w - - 0 1');
    expect(game.play('a7', 'a8', promotion: 'n'), true);
    expect(game.position.get('a8')?.type.name, 'n');
  });
  test('stalemate is not checkmate', () {
    final game = ChessSession(fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
    expect(game.position.in_stalemate, true);
    expect(game.status, contains('stalemate'));
  });
  test('save replay preserves repetition history and undo', () {
    final game = ChessSession();
    for (final move in ['Nf3', 'Nf6', 'Ng1', 'Ng8', 'Nf3', 'Nf6', 'Ng1', 'Ng8']) {
      expect(game.playSan(move), true);
    }
    final restored = ChessSession.fromJson(game.toJson());
    expect(restored.position.fen, game.position.fen);
    expect(restored.position.in_threefold_repetition, true);
    restored.undo();
    expect(restored.ended, false);
  });
  test('every AI level chooses a legal move without changing the game', () async {
    for (var level = 0; level < 3; level++) {
      final game = ChessSession();
      final before = game.position.fen;
      final move = await chooseChessMove(game, level, random: Random(3));
      expect(game.position.fen, before);
      expect(game.play(move!['from']!, move['to']!, promotion: move['promotion'] ?? 'q'), true);
    }
  });
  test('cancelled AI never returns a stale move', () async {
    expect(await chooseChessMove(ChessSession(), 2, cancelled: () => true), isNull);
  });
}
