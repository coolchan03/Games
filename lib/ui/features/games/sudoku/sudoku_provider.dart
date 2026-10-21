import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../common/campaign_progress.dart';
import 'sudoku_engine.dart';

part 'sudoku_provider.g.dart';

class SudokuState {
  final IList<IList<int>> initialBoard;
  final IList<IList<int>> currentBoard;
  final IList<IList<int>> solvedBoard;
  final int levelNumber;
  final int? selectedRow;
  final int? selectedCol;
  final bool isSolved;

  SudokuState({
    required this.initialBoard,
    required this.currentBoard,
    required this.solvedBoard,
    required this.levelNumber,
    this.selectedRow,
    this.selectedCol,
    this.isSolved = false,
  });

  SudokuState copyWith({
    IList<IList<int>>? currentBoard,
    int? selectedRow,
    int? selectedCol,
    bool? isSolved,
  }) {
    return SudokuState(
      initialBoard: initialBoard,
      currentBoard: currentBoard ?? this.currentBoard,
      solvedBoard: solvedBoard,
      levelNumber: levelNumber,
      selectedRow: selectedRow ?? this.selectedRow,
      selectedCol: selectedCol ?? this.selectedCol,
      isSolved: isSolved ?? this.isSolved,
    );
  }
}

@riverpod
class SudokuNotifier extends _$SudokuNotifier {
  static const int boardSize = 9;
  int _generation = 0;

  @override
  Future<SudokuState> build() async {
    final level = CampaignProgress.selectedLevel(
        'sudoku', count: SudokuEngine.campaignLevelCount);
    return _generateNewGame(level);
  }

  Future<SudokuState> _generateNewGame(int level) async {
    final puzzle = await compute(SudokuEngine.generateCampaignPuzzle, level);
    final flat = CampaignProgress.loadActive('sudoku', level, maxLength: 81);
    var restored = false;
    if (flat != null && flat.length == 81) {
      restored = true;
      for (var i = 0; i < 81; i++) {
        final original = puzzle.initial[i ~/ 9][i % 9];
        if (flat[i] < 0 || flat[i] > 9 ||
            (original != 0 && flat[i] != original)) {
          restored = false;
          break;
        }
      }
    }
    final current = restored
        ? [for (var row = 0; row < 9; row++)
            [for (var col = 0; col < 9; col++) flat![row * 9 + col]]]
        : [for (final row in puzzle.initial) List<int>.from(row)];
    return SudokuState(
      initialBoard: puzzle.initial.map((r) => r.lock).toIList(),
      currentBoard: current.map((r) => r.lock).toIList(),
      solvedBoard: puzzle.solution.map((r) => r.lock).toIList(),
      levelNumber: level,
    );
  }

  Future<void> loadLevel(int level) async {
    if (level < 1 || level > SudokuEngine.campaignLevelCount) return;
    final serial = ++_generation;
    state = const AsyncValue.loading();
    final next = await AsyncValue.guard(() => _generateNewGame(level));
    if (serial != _generation) return;
    state = next;
    if (next.hasValue) {
      unawaited(CampaignProgress.saveSelected('sudoku', level));
    }
  }

  /// Replay the same seeded puzzle from its original clues, not a new board.
  Future<void> initGame() async {
    final level = state.value?.levelNumber ??
        CampaignProgress.selectedLevel('sudoku',
            count: SudokuEngine.campaignLevelCount);
    await CampaignProgress.clearActive('sudoku', level);
    await loadLevel(level);
  }

  void selectCell(int r, int c) {
    if (!state.hasValue || r < 0 || r >= boardSize ||
        c < 0 || c >= boardSize) return;
    state = AsyncValue.data(state.value!.copyWith(
        selectedRow: r, selectedCol: c));
  }

  Future<void> setNumber(int num) async {
    if (!state.hasValue || num < 0 || num > 9) return;
    final currentState = state.value!;
    if (currentState.selectedRow == null ||
        currentState.selectedCol == null || currentState.isSolved) return;
    final r = currentState.selectedRow!;
    final c = currentState.selectedCol!;
    if (currentState.initialBoard[r][c] != 0) return;

    final updated = currentState.currentBoard
        .map((row) => row.toList()).toList();
    updated[r][c] = updated[r][c] == num ? 0 : num;
    final complete = updated.every((row) => !row.contains(0));

    final solved = complete && await compute(SudokuEngine.isCorrectWrapper, {
      'board': updated,
      'solvedBoard': currentState.solvedBoard
          .map((row) => row.toList()).toList(),
    });

    // Do not overwrite another puzzle's state if the player switched levels
    // while a background completion check was running.
    if (!state.hasValue ||
        state.value!.levelNumber != currentState.levelNumber ||
        state.value!.currentBoard != currentState.currentBoard) return;

    state = AsyncValue.data(currentState.copyWith(
      currentBoard: updated.map((row) => row.lock).toIList(),
      isSolved: solved,
    ));
    if (solved) {
      final completed = CampaignProgress.load(
        'sudoku', maxLevel: SudokuEngine.campaignLevelCount,
      )..add(currentState.levelNumber);
      unawaited(CampaignProgress.save('sudoku', completed));
      unawaited(CampaignProgress.clearActive(
          'sudoku', currentState.levelNumber));
    } else {
      unawaited(CampaignProgress.saveActive(
        'sudoku', currentState.levelNumber,
        [for (final row in updated) ...row],
      ));
    }
  }
}
