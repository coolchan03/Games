import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../providers/user_providers.dart';
import '../common/campaign_progress.dart';
import 'minesweeper_engine.dart';

part 'minesweeper_provider.g.dart';

class MinesweeperState {
  final List<List<MinesweeperCell>> board;
  final bool isGameOver;
  final bool isWon;
  final int minesRemaining;
  final int totalMines;
  final int levelNumber;
  final bool firstMove;

  MinesweeperState({
    required this.board,
    this.isGameOver = false,
    this.isWon = false,
    required this.minesRemaining,
    required this.totalMines,
    required this.levelNumber,
    this.firstMove = true,
  });

  MinesweeperState copyWith({
    List<List<MinesweeperCell>>? board,
    bool? isGameOver,
    bool? isWon,
    int? minesRemaining,
    bool? firstMove,
  }) {
    return MinesweeperState(
      board: board ?? this.board,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      minesRemaining: minesRemaining ?? this.minesRemaining,
      firstMove: firstMove ?? this.firstMove,
      totalMines: totalMines,
      levelNumber: levelNumber,
    );
  }
}

@riverpod
class MinesweeperNotifier extends _$MinesweeperNotifier {
  late MinesweeperEngine _engine;
  static const int rows = 10;
  static const int cols = 8;
  // The mine count now grows with the campaign instead of being fixed at 12.

  @override
  MinesweeperState build() {
    final level = CampaignProgress.selectedLevel(
      'minesweeper',
      count: MinesweeperEngine.campaignLevelCount,
    );
    return _initialState(level);
  }

  MinesweeperState _initialState(int level) {
    final mines = MinesweeperEngine.minesForLevel(level);
    _engine = MinesweeperEngine(
      rows: rows,
      cols: cols,
      mineCount: mines,
      seed: MinesweeperEngine.seedForLevel(level),
    );
    return MinesweeperState(
      board: _engine.generateBoard(),
      levelNumber: level,
      totalMines: mines,
      minesRemaining: mines,
    );
  }

  void reset() => state = _initialState(state.levelNumber);

  void loadLevel(int level) {
    if (level < 1 || level > MinesweeperEngine.campaignLevelCount) return;
    state = _initialState(level);
    unawaited(CampaignProgress.saveSelected('minesweeper', level));
  }

  void revealCell(int r, int c) {
    if (state.isGameOver || state.isWon) return;
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    if (state.board[r][c].state != CellState.hidden) return;

    var newBoard = [
      for (final row in state.board) List<MinesweeperCell>.from(row),
    ];
    final first = state.firstMove;
    if (first) {
      // Preserve flags players set before the first reveal. Changing the
      // first-click location only changes the hidden layout, not user marks.
      final flagged = <int>{
        for (var index = 0; index < rows * cols; index++)
          if (state.board[index ~/ cols][index % cols].state ==
              CellState.flagged)
            index,
      };
      newBoard = _engine.generateBoard(startRow: r, startCol: c);
      for (final index in flagged) {
        final rr = index ~/ cols;
        final cc = index % cols;
        newBoard[rr][cc] = newBoard[rr][cc].copyWith(state: CellState.flagged);
      }
    }

    if (newBoard[r][c].isMine) {
      for (final row in newBoard) {
        for (var ci = 0; ci < row.length; ci++) {
          if (row[ci].isMine) {
            row[ci] = row[ci].copyWith(state: CellState.revealed);
          }
        }
      }
      state = state.copyWith(
        board: newBoard, isGameOver: true, firstMove: false,
      );
      return;
    }

    newBoard = _engine.revealEmptyCells(newBoard, r, c);
    final won = _engine.checkWin(newBoard);
    state = state.copyWith(
      board: newBoard, isWon: won, firstMove: false,
    );

    if (won) {
      final completed = CampaignProgress.load(
        'minesweeper', maxLevel: MinesweeperEngine.campaignLevelCount,
      )..add(state.levelNumber);
      unawaited(CampaignProgress.save('minesweeper', completed));
      unawaited(ref.read(gameStreakNotifierProvider.notifier)
          .completeGame('minesweeper', xpAmount: 30));
    }
  }

  void toggleFlag(int r, int c) {
    if (state.isGameOver || state.isWon) return;
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    if (state.board[r][c].state == CellState.revealed) return;

    final newBoard = [
      for (final row in state.board) List<MinesweeperCell>.from(row),
    ];
    final currentCell = newBoard[r][c];
    var adjustment = 0;
    if (currentCell.state == CellState.hidden) {
      if (state.minesRemaining <= 0) return;
      newBoard[r][c] = currentCell.copyWith(state: CellState.flagged);
      adjustment = -1;
    } else if (currentCell.state == CellState.flagged) {
      newBoard[r][c] = currentCell.copyWith(state: CellState.hidden);
      adjustment = 1;
    }
    state = state.copyWith(
      board: newBoard,
      minesRemaining: state.minesRemaining + adjustment,
    );
  }
}
