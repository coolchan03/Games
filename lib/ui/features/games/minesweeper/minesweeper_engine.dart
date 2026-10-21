import 'dart:math';

enum CellState { hidden, revealed, flagged }

class MinesweeperCell {
  final int row;
  final int col;
  final bool isMine;
  final int neighborMines;
  final CellState state;

  const MinesweeperCell({
    required this.row,
    required this.col,
    required this.isMine,
    this.neighborMines = 0,
    this.state = CellState.hidden,
  });

  MinesweeperCell copyWith({
    CellState? state,
  }) {
    return MinesweeperCell(
      row: row,
      col: col,
      isMine: isMine,
      neighborMines: neighborMines,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinesweeperCell &&
          row == other.row &&
          col == other.col &&
          isMine == other.isMine &&
          neighborMines == other.neighborMines &&
          state == other.state;

  @override
  int get hashCode => Object.hash(row, col, isMine, neighborMines, state);
}

class MinesweeperEngine {
  final int rows;
  final int cols;
  final int mineCount;
  /// Every chapter has a distinct deterministic seed and a slightly
  /// larger mine count. These are replayable challenges, not random restarts.
  static const int campaignLevelCount = 20;

  static int minesForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, campaignLevelCount, 'level');
    return 8 + level; // 9 on level 1, 28 on level 20.
  }

  static int seedForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, campaignLevelCount, 'level');
    return 33017 + level * 7919;
  }

  final int? seed;

  MinesweeperEngine({
    this.rows = 10,
    this.cols = 8,
    this.mineCount = 12,
    this.seed,
  }) {
    if (rows < 1 || cols < 1 || mineCount < 0 || mineCount >= rows * cols) {
      throw ArgumentError('Invalid Minesweeper board size or mine count');
    }
  }

  List<List<MinesweeperCell>> generateBoard({int? startRow, int? startCol}) {
    if ((startRow == null) != (startCol == null)) {
      throw ArgumentError('Both safe-start coordinates are required');
    }
    if (startRow != null &&
        (startRow < 0 || startRow >= rows ||
            startCol! < 0 || startCol >= cols)) {
      throw RangeError('Safe first move must be inside the board');
    }

    // A fixed seed together with a first-click coordinate always reproduces
    // the exact same hidden mine layout after an app restart.
    final random = seed == null
        ? Random()
        : Random(seed! + (startRow ?? -1) * 131 + (startCol ?? -1) * 17);
    final available = <int>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          if (startRow == null ||
              (r - startRow).abs() > 1 || (c - startCol!).abs() > 1)
            r * cols + c,
    ];
    if (mineCount > available.length) {
      throw ArgumentError('Too many mines to protect the first 3x3 area');
    }
    available.shuffle(random);
    final mines = available.take(mineCount).toSet();
    final mineLocations = List<List<bool>>.generate(
      rows,
      (r) => List<bool>.generate(cols, (c) => mines.contains(r * cols + c)),
    );

    List<List<MinesweeperCell>> board = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        int neighbors = 0;
        for (int i = -1; i <= 1; i++) {
          for (int j = -1; j <= 1; j++) {
            int nr = r + i;
            int nc = c + j;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              if (mineLocations[nr][nc]) neighbors++;
            }
          }
        }
        return MinesweeperCell(
          row: r,
          col: c,
          isMine: mineLocations[r][c],
          neighborMines: neighbors,
        );
      });
    });

    return board;
  }

  List<List<MinesweeperCell>> revealEmptyCells(List<List<MinesweeperCell>> board, int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return board;
    if (board[r][c].state != CellState.hidden || board[r][c].isMine) return board;

    board[r][c] = board[r][c].copyWith(state: CellState.revealed);

    if (board[r][c].neighborMines == 0) {
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          revealEmptyCells(board, r + i, c + j);
        }
      }
    }
    return board;
  }

  bool checkWin(List<List<MinesweeperCell>> board) {
    for (var row in board) {
      for (var cell in row) {
        if (!cell.isMine && cell.state != CellState.revealed) {
          return false;
        }
      }
    }
    return true;
  }
}
