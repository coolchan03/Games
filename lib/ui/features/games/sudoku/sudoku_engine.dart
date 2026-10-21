import 'dart:math';

class SudokuCampaignPuzzle {
  final List<List<int>> initial;
  final List<List<int>> solution;
  final int level;
  final int clues;

  SudokuCampaignPuzzle({
    required this.initial,
    required this.solution,
    required this.level,
    required this.clues,
  });
}

class SudokuEngine {
  SudokuEngine({int? seed})
      : _random = seed == null ? Random() : Random(seed);

  final Random _random;
  static const int campaignLevelCount = 20;
  static const int size = 9;
  static const int boxSize = 3;

  static int cluesForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, campaignLevelCount, 'level');
    return 44 - ((level - 1) * 16 ~/ 19);
  }

  static SudokuCampaignPuzzle generateCampaignPuzzle(int level) {
    final engine = SudokuEngine(seed: 9017 + 5573 * level);
    final solved = engine.generateBoard();
    final initial = engine.createPuzzle(solved, cluesForLevel(level));
    return SudokuCampaignPuzzle(
      initial: initial,
      solution: solved,
      level: level,
      clues: initial.expand((row) => row).where((n) => n != 0).length,
    );
  }

  /// Counts up to [limit] solutions, so uniqueness checks terminate early.
  static int countSolutions(List<List<int>> puzzle, {int limit = 2}) {
    if (limit < 1 || puzzle.length != 9 ||
        puzzle.any((row) => row.length != 9 ||
            row.any((value) => value < 0 || value > 9))) return 0;
    final copy = [for (final row in puzzle) List<int>.from(row)];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final value = copy[r][c];
        if (value == 0) continue;
        copy[r][c] = 0;
        final valid = isValid(copy, r, c, value);
        copy[r][c] = value;
        if (!valid) return 0;
      }
    }
    final count = SudokuEngine()._solve(copy, 0);
    return count > limit ? limit : count;
  }

  List<List<int>> generateBoard() {
    List<List<int>> board = List.generate(size, (_) => List.filled(size, 0));
    _fillBoard(board);
    return board;
  }

  static List<List<int>> generateFullBoard([dynamic _]) {
    return SudokuEngine().generateBoard();
  }

  static List<List<int>> generateInitialPuzzle(Map<String, dynamic> params) {
    final solved = params['solved'] as List<List<int>>;
    final clues = params['clues'] as int;
    return SudokuEngine().createPuzzle(solved, clues);
  }

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(size, (i) => i + 1)..shuffle(_random);
          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool isValid(dynamic board, int row, int col, int num) {
    for (int i = 0; i < size; i++) {
      if (i != col && board[row][i] == num) return false;
    }
    for (int i = 0; i < size; i++) {
      if (i != row && board[i][col] == num) return false;
    }
    int boxRow = (row ~/ boxSize) * boxSize;
    int boxCol = (col ~/ boxSize) * boxSize;
    for (int i = 0; i < boxSize; i++) {
      for (int j = 0; j < boxSize; j++) {
        int r = boxRow + i;
        int c = boxCol + j;
        if ((r != row || c != col) && board[r][c] == num) return false;
      }
    }
    return true;
  }

  bool _isValid(dynamic board, int row, int col, int num) {
    return SudokuEngine.isValid(board, row, col, num);
  }

  List<List<int>> createPuzzle(List<List<int>> solvedBoard, int clues) {
    List<List<int>> puzzle =
        List.generate(size, (r) => List.from(solvedBoard[r]));
    int totalCells = size * size;
    int toRemove = totalCells - clues;
    toRemove = toRemove.clamp(0, totalCells - 17);

    List<List<int>> candidates = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        candidates.add([r, c]);
      }
    }
    candidates.shuffle(_random);

    int removed = 0;
    for (var candidate in candidates) {
      if (removed >= toRemove) break;
      int r = candidate[0];
      int c = candidate[1];
      if (puzzle[r][c] == 0) continue;

      int backup = puzzle[r][c];
      puzzle[r][c] = 0;

      if (_countSolutions(puzzle) == 1) {
        removed++;
      } else {
        puzzle[r][c] = backup;
      }
    }
    return puzzle;
  }

  int _countSolutions(List<List<int>> board) {
    return _solve(board, 0);
  }

  int _solve(List<List<int>> board, int count) {
    if (count > 1) return count;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (board[row][col] == 0) {
          for (int num = 1; num <= size; num++) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              count = _solve(board, count);
              board[row][col] = 0;
              if (count > 1) return count;
            }
          }
          return count;
        }
      }
    }
    return count + 1;
  }

  bool isComplete(List<List<int>> board) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool isCorrect(List<List<int>> board, List<List<int>> solvedBoard) {
    if (!isComplete(board)) return false;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        int num = board[r][c];
        board[r][c] = 0;
        bool valid = _isValid(board, r, c, num);
        board[r][c] = num;
        if (!valid) return false;
      }
    }
    return true;
  }

  static bool isCorrectWrapper(Map<String, dynamic> params) {
    final engine = SudokuEngine();
    final board = params['board'] as List<List<int>>;
    final solvedBoard = params['solvedBoard'] as List<List<int>>;
    return engine.isCorrect(board, solvedBoard);
  }
}
