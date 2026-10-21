import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'classic_maze_engine.dart';
import '../../../../providers/user_providers.dart';
import '../common/campaign_progress.dart';

part 'classic_maze_provider.g.dart';

class ClassicMazeState {
  final List<List<int>> grid;
  final int size;
  final int levelNumber;
  final int playerRow;
  final int playerCol;
  final int exitRow;
  final int exitCol;
  final List<List<int>> visitedPath;
  final int moves;
  final bool isVictory;
  final bool isLoading;
  final bool autoMoveEnabled;

  ClassicMazeState({
    required this.grid,
    required this.size,
    required this.levelNumber,
    required this.playerRow,
    required this.playerCol,
    required this.exitRow,
    required this.exitCol,
    required this.visitedPath,
    this.moves = 0,
    this.isVictory = false,
    this.isLoading = true,
    this.autoMoveEnabled = false,
  });

  ClassicMazeState copyWith({
    int? playerRow,
    int? playerCol,
    List<List<int>>? visitedPath,
    int? moves,
    bool? isVictory,
    bool? autoMoveEnabled,
  }) {
    return ClassicMazeState(
      grid: grid,
      size: size,
      levelNumber: levelNumber,
      playerRow: playerRow ?? this.playerRow,
      playerCol: playerCol ?? this.playerCol,
      exitRow: exitRow,
      exitCol: exitCol,
      visitedPath: visitedPath ?? this.visitedPath,
      moves: moves ?? this.moves,
      isVictory: isVictory ?? this.isVictory,
      isLoading: isLoading,
      autoMoveEnabled: autoMoveEnabled ?? this.autoMoveEnabled,
    );
  }
}

@riverpod
class ClassicMazeNotifier extends _$ClassicMazeNotifier {
  @override
  ClassicMazeState build() {
    return ClassicMazeState(
      grid: const [],
      size: 0,
      levelNumber: 1,
      playerRow: 0,
      playerCol: 0,
      exitRow: 0,
      exitCol: 0,
      visitedPath: const [],
      isLoading: true,
    );
  }

  /// Builds a deterministic maze, then validates the stored breadcrumb walk.
  /// Corrupt or outdated progress must never position a player inside a wall.
  ClassicMazeState _stateForLevel(int number) {
    final level = ClassicMazeEngine.campaignLevel(number);
    var path = <List<int>>[[level.startR, level.startC]];
    var moves = 0;
    final stored = CampaignProgress.loadActive('classic_maze', number,
        maxLength: 6001);
    if (stored != null && stored.length >= 2 &&
        stored.first >= 0 && stored.first <= 100000) {
      final candidate = <List<int>>[];
      var valid = true;
      for (final cellIndex in stored.skip(1)) {
        final r = cellIndex ~/ level.size;
        final c = cellIndex % level.size;
        if (cellIndex < 0 || r >= level.size || c >= level.size ||
            level.grid[r][c] != 0) {
          valid = false;
          break;
        }
        if (candidate.isNotEmpty) {
          final last = candidate.last;
          if ((last[0] - r).abs() + (last[1] - c).abs() != 1) {
            valid = false;
            break;
          }
        }
        candidate.add([r, c]);
      }
      if (valid && candidate.isNotEmpty &&
          candidate.first[0] == level.startR &&
          candidate.first[1] == level.startC &&
          stored.first >= candidate.length - 1 &&
          !(candidate.last[0] == level.exitR &&
            candidate.last[1] == level.exitC)) {
        path = candidate;
        moves = stored.first;
      }
    }
    final last = path.last;
    return ClassicMazeState(
      grid: level.grid,
      size: level.size,
      levelNumber: number,
      playerRow: last[0],
      playerCol: last[1],
      exitRow: level.exitR,
      exitCol: level.exitC,
      visitedPath: path,
      moves: moves,
      isVictory: false,
      isLoading: false,
      autoMoveEnabled: state.autoMoveEnabled,
    );
  }

  void initGame() {
    loadLevel(CampaignProgress.selectedLevel(
        'classic_maze', count: ClassicMazeEngine.campaignLevelCount));
  }

  void loadLevel(int level) {
    if (level < 1 || level > ClassicMazeEngine.campaignLevelCount) return;
    state = _stateForLevel(level);
    unawaited(CampaignProgress.saveSelected('classic_maze', level));
  }

  void toggleAutoMove() {
    state = state.copyWith(autoMoveEnabled: !state.autoMoveEnabled);
  }

  bool movePlayer(int dr, int dc) {
    if (state.isVictory || state.isLoading) return false;
    final current = state;
    var nr = current.playerRow + dr;
    var nc = current.playerCol + dc;
    if (nr < 0 || nr >= current.size || nc < 0 || nc >= current.size ||
        current.grid[nr][nc] == 1) return false;

    var previousR = current.playerRow;
    var previousC = current.playerCol;
    final path = [for (final cell in current.visitedPath) List<int>.of(cell)];

    void step(int r, int c) {
      if (path.length > 1 &&
          path[path.length - 2][0] == r &&
          path[path.length - 2][1] == c) {
        path.removeLast();
      } else {
        path.add([r, c]);
      }
    }

    step(nr, nc);
    var movesAdded = 1;
    if (current.autoMoveEnabled) {
      while (nr != current.exitRow || nc != current.exitCol) {
        final neighbors = <List<int>>[];
        for (final dir in const [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
          final r = nr + dir[0];
          final c = nc + dir[1];
          if (r >= 0 && r < current.size && c >= 0 && c < current.size &&
              current.grid[r][c] == 0 &&
              (r != previousR || c != previousC)) {
            neighbors.add([r, c]);
          }
        }
        if (neighbors.length != 1) break;
        final next = neighbors.first;
        previousR = nr;
        previousC = nc;
        nr = next[0];
        nc = next[1];
        step(nr, nc);
        movesAdded++;
      }
    }

    final won = nr == current.exitRow && nc == current.exitCol;
    state = current.copyWith(
      playerRow: nr,
      playerCol: nc,
      visitedPath: path,
      moves: current.moves + movesAdded,
      isVictory: won,
    );
    if (won) {
      final completed = CampaignProgress.load(
        'classic_maze', maxLevel: ClassicMazeEngine.campaignLevelCount,
      )..add(current.levelNumber);
      unawaited(CampaignProgress.save('classic_maze', completed));
      unawaited(CampaignProgress.clearActive(
          'classic_maze', current.levelNumber));
      unawaited(ref.read(gameStreakNotifierProvider.notifier)
          .completeGame('classic_maze', xpAmount: 25));
    } else if (path.length <= 6000) {
      unawaited(CampaignProgress.saveActive(
        'classic_maze',
        current.levelNumber,
        [state.moves, for (final cell in path) cell[0] * current.size + cell[1]],
      ));
    }
    return true;
  }

  void reset() {
    final level = state.isLoading ? CampaignProgress.selectedLevel(
      'classic_maze', count: ClassicMazeEngine.campaignLevelCount,
    ) : state.levelNumber;
    unawaited(CampaignProgress.clearActive('classic_maze', level));
    loadLevel(level);
  }
}
