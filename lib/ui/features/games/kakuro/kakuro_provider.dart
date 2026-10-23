import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../common/campaign_progress.dart';
import 'kakuro_campaign_data.dart';
import 'kakuro_engine.dart';

part 'kakuro_provider.g.dart';

class KakuroState {
  final KakuroLevel level;
  final Map<Point<int>, int?> currentValues;
  final int? selectedRow;
  final int? selectedCol;
  final bool isSolved;

  const KakuroState({
    required this.level,
    required this.currentValues,
    this.selectedRow,
    this.selectedCol,
    this.isSolved = false,
  });

  KakuroState copyWith({
    KakuroLevel? level,
    Map<Point<int>, int?>? currentValues,
    int? selectedRow,
    int? selectedCol,
    bool? isSolved,
  }) => KakuroState(
        level: level ?? this.level,
        currentValues: currentValues ?? this.currentValues,
        selectedRow: selectedRow ?? this.selectedRow,
        selectedCol: selectedCol ?? this.selectedCol,
        isSolved: isSolved ?? this.isSolved,
      );
}

@riverpod
class KakuroNotifier extends _$KakuroNotifier {
  static const String gameId = 'kakuro';
  Future<void> _pendingWrites = Future<void>.value();

  void _queueSave(Future<void> Function() write) {
    _pendingWrites = _pendingWrites.then((_) => write()).catchError((Object _) {
      // Offline storage is optional; never stop an otherwise playable game.
    });
  }

  Future<void> flushProgress() => _pendingWrites;

  @override
  KakuroState build() {
    final number = CampaignProgress.selectedLevel(
      gameId, count: KakuroCampaignData.levelCount,
    );
    return _buildState(number, restore: true);
  }

  KakuroState _buildState(int number, {required bool restore}) {
    final level = KakuroEngine.campaignLevel(number);
    final values = KakuroEngine.startingValues(level);
    if (restore) {
      final saved = CampaignProgress.loadActive(
        gameId, number, maxLength: level.size * level.size * 2,
      );
      if (saved != null && saved.length.isEven) {
        for (var i = 0; i < saved.length; i += 2) {
          final index = saved[i];
          final digit = saved[i + 1];
          if (index < 0 || index >= level.size * level.size ||
              digit < 1 || digit > 9) continue;
          final row = index ~/ level.size;
          final col = index % level.size;
          final cell = level.grid[row][col];
          if (cell.isWhite && !cell.isGiven) {
            values[Point(col, row)] = digit;
          }
        }
      }
    }
    return KakuroState(level: level, currentValues: values);
  }

  void loadLevel(int number) {
    state = _buildState(number, restore: true);
    _queueSave(() => CampaignProgress.saveSelected(gameId, number));
  }

  void selectCell(int row, int col) {
    if (state.isSolved || row < 0 || col < 0 ||
        row >= state.level.size || col >= state.level.size) return;
    final cell = state.level.grid[row][col];
    if (!cell.isWhite || cell.isGiven) return;
    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  void setCellValue(int? digit) {
    if (state.isSolved || (digit != null && (digit < 1 || digit > 9))) return;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (row == null || col == null ||
        state.level.grid[row][col].isGiven) return;
    final values = Map<Point<int>, int?>.of(state.currentValues);
    values[Point(col, row)] = digit;
    final completed = KakuroEngine.checkSolved(state.level, values);
    final number = state.level.levelNumber;
    state = state.copyWith(currentValues: values, isSolved: completed);
    if (completed) {
      _queueSave(() async {
        final finished = CampaignProgress.load(gameId)..add(number);
        await CampaignProgress.save(gameId, finished);
        await CampaignProgress.clearActive(gameId, number);
      });
    } else {
      final entries = <int>[];
      for (var r = 0; r < state.level.size; r++) {
        for (var c = 0; c < state.level.size; c++) {
          final cell = state.level.grid[r][c];
          final value = values[Point(c, r)];
          if (cell.isWhite && !cell.isGiven && value != null) {
            entries..add(r * state.level.size + c)..add(value);
          }
        }
      }
      _queueSave(() => CampaignProgress.saveActive(gameId, number, entries));
    }
  }

  void restartLevel() {
    final number = state.level.levelNumber;
    _queueSave(() => CampaignProgress.clearActive(gameId, number));
    state = _buildState(number, restore: false);
  }

  // Keep the old controls usable for callers that haven't migrated.
  void reset() => restartLevel();

  void newGame() {
    final next = state.level.levelNumber == KakuroCampaignData.levelCount
        ? 1 : state.level.levelNumber + 1;
    loadLevel(next);
  }
}
