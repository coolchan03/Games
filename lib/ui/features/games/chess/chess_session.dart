import 'dart:math';
import 'package:chess/chess.dart' as rules;

/// Rules: chess.dart 0.8.1 (MIT/BSD). Saves replay moves to retain repetition.
class ChessSession {
  final rules.Chess position;
  final String initialFen;
  final List<String> history = [];
  ChessSession({String? fen})
      : initialFen = fen ?? rules.Chess().fen,
        position = rules.Chess.fromFEN(fen ?? rules.Chess().fen);
  bool get whiteToMove => position.turn == rules.Color.WHITE;
  bool get ended => position.game_over;
  String get status {
    if (position.in_checkmate) return '${whiteToMove ? 'Black' : 'White'} wins by checkmate';
    if (position.in_stalemate) return 'Draw by stalemate';
    if (position.in_threefold_repetition) return 'Draw by threefold repetition';
    if (position.insufficient_material) return 'Draw: insufficient material';
    if (position.in_draw) return 'Draw by the fifty-move rule';
    return '${whiteToMove ? 'White' : 'Black'} to move${position.in_check ? ' - check' : ''}';
  }
  // chess.dart 0.8.1 omits promotion from verbose maps despite its API docs.
  // Normalize from Move objects so underpromotion and the chooser are correct.
  List<Map> get legalMoves => position.generate_moves().map((move) => <String, dynamic>{
    ...position.make_pretty(move),
    if (move.promotion != null) 'promotion': move.promotion!.name,
  }).toList();
  bool playSan(String san) {
    if (ended || !position.move(san)) return false;
    history.add(san);
    return true;
  }
  bool play(String from, String to, {String promotion = 'q'}) {
    if (ended) return false;
    for (final move in legalMoves) {
      if (move['from'] == from && move['to'] == to &&
          (move['promotion'] == null || move['promotion'] == promotion)) {
        return playSan(move['san'] as String);
      }
    }
    return false;
  }
  void undo() {
    if (history.isEmpty) return;
    position.undo(); history.removeLast();
  }
  Map<String, dynamic> toJson() => {'version': 1, 'initialFen': initialFen,
    'history': List<String>.from(history)};
  factory ChessSession.fromJson(Map<String, dynamic> data) {
    if (data['version'] != 1 || data['initialFen'] is! String || data['history'] is! List) {
      throw const FormatException('Unsupported chess save');
    }
    final session = ChessSession(fen: data['initialFen'] as String);
    final moves = data['history'] as List;
    if (moves.length > 2000) throw const FormatException('Chess history too long');
    for (final move in moves) {
      if (move is! String || !session.playSan(move)) {
        throw const FormatException('Illegal move in saved chess game');
      }
    }
    return session;
  }
}

/// A bounded, cooperative search; not a heavyweight external engine.
Future<Map<String, String>?> chooseChessMove(ChessSession session, int difficulty,
    {Random? random, bool Function()? cancelled}) async {
  final board = session.position.copy();
  if (board.game_over) return null;
  final roots = board.generate_moves()..shuffle(random ?? Random());
  if (roots.isEmpty) return null;
  var best = roots.first;
  var nodes = 0;
  final budget = difficulty >= 2 ? 3500 : 900;
  const values = {'p': 100, 'n': 320, 'b': 330, 'r': 500, 'q': 900, 'k': 0};
  int evaluate() {
    var total = 0;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.get('${'abcdefgh'[col]}${8 - row}');
        if (piece == null) continue;
        final center = 14 - (col * 2 - 7).abs() - (row * 2 - 7).abs();
        final value = values[piece.type.name]! + (piece.type.name == 'k' ? 0 : center);
        total += piece.color == board.turn ? value : -value;
      }
    }
    return total;
  }
  Future<int> search(int depth, int alpha, int beta, int ply) async {
    nodes++;
    if (nodes % 64 == 0) await Future<void>.delayed(Duration.zero);
    if (cancelled?.call() == true || nodes >= budget) return evaluate();
    if (board.in_checkmate) return -100000 + ply;
    if (board.in_draw) return 0;
    if (depth == 0) return evaluate();
    final moves = board.generate_moves()
      ..sort((a, b) => (b.captured == null ? 0 : 1).compareTo(a.captured == null ? 0 : 1));
    var score = -1000000;
    for (final move in moves) {
      board.make_move(move);
      final value = -await search(depth - 1, -beta, -alpha, ply + 1);
      board.undo_move();
      score = max(score, value); alpha = max(alpha, value);
      if (alpha >= beta || nodes >= budget || cancelled?.call() == true) break;
    }
    return score;
  }
  if (difficulty > 0) {
    for (var depth = 1; depth <= (difficulty >= 2 ? 3 : 2); depth++) {
      var iterationBest = best, iterationScore = -1000000;
      for (final move in roots) {
        board.make_move(move);
        final score = -await search(depth - 1, -1000000, 1000000, 1);
        board.undo_move();
        if (score > iterationScore) { iterationBest = move; iterationScore = score; }
        if (nodes >= budget || cancelled?.call() == true) break;
      }
      if (nodes >= budget || cancelled?.call() == true) break;
      best = iterationBest;
    }
  }
  if (cancelled?.call() == true) return null;
  return {'from': best.fromAlgebraic, 'to': best.toAlgebraic,
    if (best.promotion != null) 'promotion': best.promotion!.name};
}
