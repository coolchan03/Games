import 'dart:math';

class NonogramPuzzle {
  final List<List<int>> rowClues;
  final List<List<int>> colClues;

  NonogramPuzzle({
    required this.rowClues,
    required this.colClues,
  });
}

class NonogramEngine {
  NonogramEngine({int? seed})
      : _random = seed == null ? Random() : Random(seed);

  final Random _random;

  /// Twenty reproducible campaign levels, starting on a 5x5 board and
  /// growing to 9x9. Do not count a random restart as a new level.
  static const int campaignLevelCount = 20;

  static int sizeForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, campaignLevelCount, 'level');
    return 5 + (level - 1) ~/ 4;
  }

  /// Called from an isolate so uniqueness checking cannot stall the UI.
  static NonogramPuzzle generateCampaignPuzzle(int level) {
    final size = sizeForLevel(level);
    for (var attempt = 0; attempt < 180; attempt++) {
      final puzzle = NonogramEngine(
        seed: 87001 + level * 7919 + attempt * 313,
      ).generatePuzzle(size);
      if (countSolutions(puzzle, size, limit: 2) == 1) return puzzle;
    }
    throw StateError('Unable to produce a uniquely solvable nonogram: $level');
  }

  /// Counts solutions only up to [limit], making a uniqueness check cheap.
  /// Candidate lines obey clue runs and required spaces between blocks.
  static int countSolutions(NonogramPuzzle puzzle, int size, {int limit = 2}) {
    if (size < 1 || size > 12 || puzzle.rowClues.length != size ||
        puzzle.colClues.length != size || limit < 1) return 0;
    final rowOptions = [
      for (final row in puzzle.rowClues) _lineOptions(row, size),
    ];
    final initialCols = [
      for (final column in puzzle.colClues) _lineOptions(column, size),
    ];
    if (rowOptions.any((choices) => choices.isEmpty) ||
        initialCols.any((choices) => choices.isEmpty)) return 0;

    var solutions = 0;
    void visit(int row, List<List<int>> columns) {
      if (solutions >= limit) return;
      if (row == size) {
        solutions++;
        return;
      }
      for (final mask in rowOptions[row]) {
        final narrowed = <List<int>>[];
        var possible = true;
        for (var column = 0; column < size; column++) {
          final bit = (mask >> column) & 1;
          final choices = columns[column].where(
            (candidate) => ((candidate >> row) & 1) == bit,
          ).toList();
          if (choices.isEmpty) {
            possible = false;
            break;
          }
          narrowed.add(choices);
        }
        if (possible) visit(row + 1, narrowed);
        if (solutions >= limit) break;
      }
    }
    visit(0, initialCols);
    return solutions;
  }

  static List<int> _lineOptions(List<int> clues, int size) {
    if (clues.any((n) => n < 0)) return const [];
    final runs = clues.where((n) => n > 0).toList();
    if (runs.isEmpty) return [0];
    final result = <int>[];
    void place(int runIndex, int first, int mask) {
      if (runIndex == runs.length) {
        result.add(mask);
        return;
      }
      final length = runs[runIndex];
      final rest = runs.skip(runIndex + 1).fold<int>(0, (a, b) => a + b)
          + (runs.length - runIndex - 1);
      final last = size - length - rest;
      for (var at = first; at <= last; at++) {
        place(runIndex + 1, at + length + 1,
            mask | (((1 << length) - 1) << at));
      }
    }
    place(0, 0, 0);
    return result;
  }

  NonogramPuzzle generatePuzzle(int size) {
    // 1. Generate a random grid
    // For a better experience, we can weight it towards being filled
    final List<List<bool>> solution = List.generate(
      size,
      (_) => List.generate(size, (_) => _random.nextDouble() > 0.45),
    );

    // 2. Generate row clues
    final List<List<int>> rowClues = [];
    for (int r = 0; r < size; r++) {
      rowClues.add(_calculateClues(solution[r]));
    }

    // 3. Generate col clues
    final List<List<int>> colClues = [];
    for (int c = 0; c < size; c++) {
      final List<bool> column = [];
      for (int r = 0; r < size; r++) {
        column.add(solution[r][c]);
      }
      colClues.add(_calculateClues(column));
    }

    return NonogramPuzzle(
      rowClues: rowClues,
      colClues: colClues,
    );
  }

  List<int> _calculateClues(List<bool> line) {
    final List<int> clues = [];
    int currentRun = 0;
    for (bool cell in line) {
      if (cell) {
        currentRun++;
      } else if (currentRun > 0) {
        clues.add(currentRun);
        currentRun = 0;
      }
    }
    if (currentRun > 0) {
      clues.add(currentRun);
    }
    return clues.isEmpty ? [0] : clues;
  }

  static bool isCorrect(List<List<int>> currentGrid, List<List<int>> rowClues, List<List<int>> colClues) {
    final size = currentGrid.length;
    final engine = NonogramEngine();

    // Check rows
    for (int r = 0; r < size; r++) {
      final List<bool> row = currentGrid[r].map((e) => e == 1).toList();
      final calculatedClues = engine._calculateClues(row);
      if (!engine._listEquals(calculatedClues, rowClues[r])) return false;
    }

    // Check columns
    for (int c = 0; c < size; c++) {
      final List<bool> column = [];
      for (int r = 0; r < size; r++) {
        column.add(currentGrid[r][c] == 1);
      }
      final calculatedClues = engine._calculateClues(column);
      if (!engine._listEquals(calculatedClues, colClues[c])) return false;
    }

    return true;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static NonogramPuzzle generatePuzzleWrapper(int size) {
    return NonogramEngine().generatePuzzle(size);
  }

  static bool isCorrectWrapper(Map<String, dynamic> params) {
    return isCorrect(
      params['grid'] as List<List<int>>,
      params['rowClues'] as List<List<int>>,
      params['colClues'] as List<List<int>>,
    );
  }
}
