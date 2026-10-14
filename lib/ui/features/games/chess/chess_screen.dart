import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'engine/ai/chess_ai.dart';
import 'engine/ai/easy_ai.dart';
import 'engine/ai/hard_ai.dart';
import 'engine/logic/san_converter.dart';
import 'engine/models/chess_move.dart';
import 'engine/models/chess_state.dart';
import 'engine/models/enums.dart';

/// Chess using the MIT-licensed rules engine and AI from z7workbench/minigames.
class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});
  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> {
  ChessState game = ChessState.initial();
  final List<ChessState> history = [];
  final List<String> sanMoves = [];
  bool vsComputer = true, thinking = false, flipped = false;
  AiLevel level = AiLevel.medium;
  int? selRow, selCol;
  List<ChessMove> targets = [];
  int generation = 0;

  bool get over =>
      game.status == GameStatus.checkmate ||
      game.status == GameStatus.stalemate ||
      game.status == GameStatus.draw;

  void newGame() => setState(() {
        generation++;
        game = ChessState.initial();
        history.clear();
        sanMoves.clear();
        selRow = selCol = null;
        targets = [];
        thinking = false;
      });

  String get status {
    if (game.status == GameStatus.checkmate) {
      final w = game.winner == PieceColor.white ? 'White' : 'Black';
      return 'Checkmate — $w wins!';
    }
    if (game.status == GameStatus.stalemate) return 'Stalemate — draw';
    if (game.status == GameStatus.draw) {
      return switch (game.drawReason) {
        DrawReason.fiftyMoveRule => 'Draw by fifty-move rule',
        DrawReason.insufficientMaterial => 'Draw — insufficient material',
        DrawReason.threefoldRepetition => 'Draw by threefold repetition',
        _ => 'Draw',
      };
    }
    if (thinking) return 'Computer is thinking…';
    final side = game.currentTurn == PieceColor.white ? 'White' : 'Black';
    return game.status == GameStatus.check ? '$side to move — check!' : '$side to move';
  }

  Future<void> commit(ChessMove move) async {
    setState(() {
      history.add(game);
      sanMoves.add(SanConverter.moveToSan(game, move));
      game = game.applyMove(move);
      selRow = selCol = null;
      targets = [];
    });
    if (vsComputer && !over && game.currentTurn == PieceColor.black) {
      await computerMove();
    }
  }

  Future<void> computerMove() async {
    final token = generation;
    setState(() => thinking = true);
    // Let the frame with the player's move paint before searching.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final ChessAi ai = level == AiLevel.easy ? EasyChessAi() : HardChessAi();
    final move = await ai.findBestMove(game,
        timeLimit: Duration(milliseconds: level == AiLevel.hard ? 1500 : 250));
    if (!mounted || token != generation) return;
    setState(() {
      thinking = false;
      if (move != null) {
        history.add(game);
        sanMoves.add(SanConverter.moveToSan(game, move));
        game = game.applyMove(move);
      }
    });
  }

  Future<PieceType?> askPromotion() => showDialog<PieceType>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Promote pawn to'),
          children: [
            for (final t in const [
              PieceType.queen,
              PieceType.rook,
              PieceType.bishop,
              PieceType.knight
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, t),
                child: Text('${t.unicodeWhite}  ${t.name[0].toUpperCase()}${t.name.substring(1)}',
                    style: const TextStyle(fontSize: 20)),
              ),
          ],
        ),
      );

  Future<void> tap(int r, int c) async {
    if (over || thinking) return;
    if (vsComputer && game.currentTurn == PieceColor.black) return;
    final moves = targets.where((m) => m.toRow == r && m.toCol == c).toList();
    if (moves.isNotEmpty) {
      var move = moves.first;
      if (moves.length > 1 || move.promotionPiece != null) {
        final choice = await askPromotion();
        if (choice == null) return;
        move = moves.firstWhere((m) => m.promotionPiece == choice,
            orElse: () => moves.first);
      }
      await commit(move);
      return;
    }
    final piece = game.pieceAt(r, c);
    setState(() {
      if (piece != null && piece.color == game.currentTurn) {
        selRow = r;
        selCol = c;
        targets = game.getLegalMovesForSquare(r, c);
      } else {
        selRow = selCol = null;
        targets = [];
      }
    });
  }

  void undo() {
    if (thinking || history.isEmpty) return;
    setState(() {
      var steps = vsComputer && history.length >= 2 ? 2 : 1;
      if (vsComputer && game.currentTurn == PieceColor.black) steps = 1;
      for (var i = 0; i < steps && history.isNotEmpty; i++) {
        game = history.removeLast();
        sanMoves.removeLast();
      }
      selRow = selCol = null;
      targets = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const light = Color(0xFFF0D9B5), dark = Color(0xFFB58863);
    final moveText = StringBuffer();
    for (var i = 0; i < sanMoves.length; i++) {
      if (i.isEven) moveText.write('${i ~/ 2 + 1}. ');
      moveText.write('${sanMoves[i]} ');
    }
    return GameScaffold(
      title: 'Chess',
      onNewGame: newGame,
      rules: 'Standard chess. Tap a piece to see its legal moves, then tap a '
          'highlighted square. Castling, en passant, promotion, check, '
          'checkmate, stalemate, threefold repetition, the fifty-move rule '
          'and insufficient material are all enforced.\n\n'
          'Against the computer you play White. Easy plays casually; Medium '
          'and Hard run an alpha-beta search with more time on Hard.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            newGame();
          },
        ),
        StatusBanner(status, highlight: over),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 64,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            itemBuilder: (context, i) {
              var r = i ~/ 8, c = i % 8;
              if (flipped) {
                r = 7 - r;
                c = 7 - c;
              }
              final piece = game.pieceAt(r, c);
              final isTarget = targets.any((m) => m.toRow == r && m.toCol == c);
              final isLast = (game.lastMoveFromRow == r && game.lastMoveFromCol == c) ||
                  (game.lastMoveToRow == r && game.lastMoveToCol == c);
              final base = (r + c).isEven ? light : dark;
              return GestureDetector(
                onTap: () => tap(r, c),
                child: Semantics(
                  label: '${ChessMove.colToFile(c)}${ChessMove.rowToRank(r)}'
                      '${piece == null ? '' : ' ${piece.color.name} ${piece.type.name}'}',
                  button: true,
                  child: Container(
                    color: selRow == r && selCol == c
                        ? Color.lerp(base, colors.primary, .55)
                        : isLast
                            ? Color.lerp(base, Colors.yellow, .4)
                            : base,
                    child: Stack(alignment: Alignment.center, children: [
                      if (piece != null)
                        FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              piece.type.unicodeBlack,
                              style: TextStyle(
                                fontSize: 40,
                                height: 1,
                                color: piece.color == PieceColor.white
                                    ? Colors.white
                                    : Colors.black,
                                shadows: [
                                  Shadow(
                                      blurRadius: 1.5,
                                      color: piece.color == PieceColor.white
                                          ? Colors.black
                                          : Colors.white54),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (isTarget)
                        FractionallySizedBox(
                          widthFactor: piece == null ? .3 : .9,
                          heightFactor: piece == null ? .3 : .9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: piece == null
                                  ? colors.primary.withValues(alpha: .55)
                                  : null,
                              border: piece == null
                                  ? null
                                  : Border.all(color: colors.primary, width: 3),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: history.isEmpty || thinking ? null : undo,
              icon: const Icon(Icons.undo),
              label: const Text('Undo')),
          OutlinedButton.icon(
              onPressed: () => setState(() => flipped = !flipped),
              icon: const Icon(Icons.swap_vert),
              label: const Text('Flip board')),
        ]),
        if (sanMoves.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(moveText.toString().trim(),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
