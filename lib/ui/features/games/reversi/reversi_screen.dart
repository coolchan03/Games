import 'dart:math';
import 'package:flutter/material.dart';
import 'engine/game_board.dart';
import 'engine/game_board_scorer.dart';

/// Offline Reversi, using FlutterFlip's BSD-licensed rules and evaluation.
class ReversiScreen extends StatefulWidget {
  const ReversiScreen({super.key});
  @override
  State<ReversiScreen> createState() => _ReversiScreenState();
}

class _ReversiScreenState extends State<ReversiScreen> {
  final Random _random = Random();
  GameBoard board = GameBoard();
  PieceType turn = PieceType.black;
  bool vsComputer = true, busy = false, finished = false;
  int difficulty = 1;

  void _newGame() => setState(() {
    board = GameBoard();
    turn = PieceType.black;
    busy = false;
    finished = false;
  });

  void _nextTurn() {
    final other = turn.opponent;
    final theirMoves = board.getMovesForPlayer(other);
    final ourMoves = board.getMovesForPlayer(turn);
    if (theirMoves.isEmpty && ourMoves.isEmpty) {
      finished = true;
    } else if (theirMoves.isNotEmpty) {
      turn = other;
    }
  }

  int _search(GameBoard current, PieceType player, int depth,
      int alpha, int beta) {
    final moves = current.getMovesForPlayer(player);
    final opposite = current.getMovesForPlayer(player.opponent);
    if (depth == 0 || (moves.isEmpty && opposite.isEmpty)) {
      return GameBoardScorer(current).getScore(PieceType.white);
    }
    if (moves.isEmpty) {
      return _search(current, player.opponent, depth - 1, alpha, beta);
    }
    if (player == PieceType.white) {
      var best = minScore;
      for (final move in moves) {
        final next = current.updateForMove(move.x, move.y, player);
        best = max(best, _search(next, player.opponent, depth - 1, alpha, beta));
        alpha = max(alpha, best);
        if (alpha >= beta) break;
      }
      return best;
    }
    var best = maxScore;
    for (final move in moves) {
      final next = current.updateForMove(move.x, move.y, player);
      best = min(best, _search(next, player.opponent, depth - 1, alpha, beta));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }

  Position _computerMove() {
    final moves = board.getMovesForPlayer(PieceType.white);
    if (difficulty == 0 || moves.length == 1) {
      return moves[_random.nextInt(moves.length)];
    }
    var best = minScore;
    final strongest = <Position>[];
    for (final move in moves) {
      final next = board.updateForMove(move.x, move.y, PieceType.white);
      final score = difficulty == 1
          ? GameBoardScorer(next).getScore(PieceType.white)
          : _search(next, PieceType.black, 2, minScore, maxScore);
      if (score > best) {
        best = score;
        strongest..clear()..add(move);
      } else if (score == best) {
        strongest.add(move);
      }
    }
    return strongest[_random.nextInt(strongest.length)];
  }

  Future<void> _playComputer() async {
    if (!vsComputer || finished || turn != PieceType.white) return;
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || !vsComputer || finished || turn != PieceType.white) return;
    final move = _computerMove();
    setState(() {
      board = board.updateForMove(move.x, move.y, PieceType.white);
      _nextTurn();
      busy = false;
    });
  }

  void _play(int row, int column) {
    if (busy || finished || (vsComputer && turn == PieceType.white)) return;
    if (!board.isLegalMove(column, row, turn)) return;
    setState(() {
      board = board.updateForMove(column, row, turn);
      _nextTurn();
    });
    if (vsComputer && !finished && turn == PieceType.white) {
      _playComputer();
    }
  }

  Widget _gameBoard(ColorScheme colors) {
    final valid = board.getMovesForPlayer(turn);
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemBuilder: (context, index) {
          final y = index ~/ 8, x = index % 8;
          final piece = board.getPieceAtLocation(x, y);
          final available = valid.any((move) => move.x == x && move.y == y);
          return InkWell(
            onTap: () => _play(y, x),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colors.primaryContainer,
              ),
              alignment: Alignment.center,
              child: piece == PieceType.empty
                  ? (available
                      ? Icon(Icons.circle, color: colors.primary.withValues(alpha: 0.35),
                          size: 13)
                      : null)
                  : FractionallySizedBox(
                      widthFactor: 0.76,
                      heightFactor: 0.76,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: piece == PieceType.black
                              ? colors.onSurface
                              : colors.surface,
                          border: Border.all(color: colors.outline, width: 1.5),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final black = board.getPieceCount(PieceType.black);
    final white = board.getPieceCount(PieceType.white);
    final label = finished
        ? black == white ? 'Draw!' : black > white ? 'Black wins!' : 'White wins!'
        : busy ? 'Computer thinking…'
        : turn == PieceType.black ? 'Black to move' : 'White to move';
    return Scaffold(
      appBar: AppBar(title: const Text('Reversi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Play against computer'),
                  value: vsComputer,
                  onChanged: (v) { vsComputer = v; _newGame(); },
                ),
                if (vsComputer)
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Easy')),
                      ButtonSegment(value: 1, label: Text('Medium')),
                      ButtonSegment(value: 2, label: Text('Hard')),
                    ],
                    selected: {difficulty},
                    onSelectionChanged: (v) {
                      difficulty = v.first;
                      _newGame();
                    },
                  ),
                const SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Black $black  •  White $white', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                _gameBoard(colors),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('New game'),
                ),
                const SizedBox(height: 8),
                const Text('Surround opposing pieces to flip them. '
                    'A player without legal moves automatically passes.',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
