import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../providers/user_providers.dart';
import '../common/campaign_progress.dart';
import 'nonogram_engine.dart';
import 'nonogram_touch.dart';

part 'nonogram_provider.g.dart';

class NonogramState {
  final List<List<int>> grid;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final bool isSolved;
  final int size;
  final int levelNumber;

  NonogramState({
    required this.grid,
    required this.rowClues,
    required this.colClues,
    this.isSolved = false,
    this.size = 5,
    this.levelNumber = 1,
  });

  NonogramState copyWith({
    List<List<int>>? grid,
    bool? isSolved,
  }) {
    return NonogramState(
      grid: grid ?? this.grid,
      rowClues: rowClues,
      colClues: colClues,
      isSolved: isSolved ?? this.isSolved,
      size: size,
      levelNumber: levelNumber,
    );
  }
}

@riverpod
class NonogramNotifier extends _$NonogramNotifier {
  int _requestSerial = 0;

  @override
  Future<NonogramState> build() async {
    return _generateInitialState(CampaignProgress.selectedLevel(
      'nonogram',
      count: NonogramEngine.campaignLevelCount,
    ));
  }

  Future<NonogramState> _generateInitialState(int level) async {
    // Unique, reproducible clue sets are generated off the UI isolate.
    final puzzle = await compute(NonogramEngine.generateCampaignPuzzle, level);
    final size = NonogramEngine.sizeForLevel(level);
    return NonogramState(
      grid: List.generate(size, (_) => List.filled(size, 0)),
      rowClues: puzzle.rowClues,
      colClues: puzzle.colClues,
      size: size,
      levelNumber: level,
    );
  }

  Future<void> reset() => loadLevel(state.value?.levelNumber ?? 1);

  Future<void> loadLevel(int level) async {
    if (level < 1 || level > NonogramEngine.campaignLevelCount) return;
    final serial = ++_requestSerial;
    state = const AsyncValue.loading();
    final next = await AsyncValue.guard(() => _generateInitialState(level));
    if (serial != _requestSerial) return;
    state = next;
    if (next.hasValue) {
      unawaited(CampaignProgress.saveSelected('nonogram', level));
    }
  }

  /// Paint every cell in one atomic move after a completed board drag.
  /// A cancelled or off-board drag is never sent here by the touch surface.
  void paintCells(Iterable<int> indices, bool isMarkMode) {
    if (!state.hasValue || state.value!.isSolved) return;
    final currentState = state.value!;
    final newGrid = paintNonogramCells(
      currentState.grid,
      indices,
      value: isMarkMode ? 2 : 1,
    );
    if (identical(newGrid, currentState.grid)) return;

    final solved = NonogramEngine.isCorrect(
      newGrid,
      currentState.rowClues,
      currentState.colClues,
    );
    state = AsyncValue.data(currentState.copyWith(
      grid: newGrid,
      isSolved: solved,
    ));
    if (solved) {
      ref.read(gameStreakNotifierProvider.notifier)
          .completeGame('nonogram', xpAmount: 25);
    }
  }

  void toggleCell(int r, int c, bool isMarkMode) {
    if (!state.hasValue || state.value!.isSolved) return;
    
    final currentState = state.value!;

    final newGrid = List.generate(
      currentState.size,
      (i) => List<int>.from(currentState.grid[i]),
    );

    final currentValue = newGrid[r][c];
    
    if (isMarkMode) {
      newGrid[r][c] = currentValue == 2 ? 0 : 2;
    } else {
      newGrid[r][c] = currentValue == 1 ? 0 : 1;
    }

    final solved = NonogramEngine.isCorrect(
      newGrid,
      currentState.rowClues,
      currentState.colClues,
    );
    
    state = AsyncValue.data(currentState.copyWith(grid: newGrid, isSolved: solved));

    if (solved) {
      ref.read(gameStreakNotifierProvider.notifier).completeGame('nonogram', xpAmount: 25);
    }
  }
}
