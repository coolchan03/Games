import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../common/campaign_progress.dart';
import 'akari_campaign_data.dart';
import 'akari_engine.dart';

part 'akari_provider.g.dart';

class AkariState {
  final IList<IList<int>> grid;
  final IList<IList<bool>> bulbs;
  final IList<IList<bool>> lit;
  final int levelNumber;
  final bool isVictory;
  final bool isLoading;

  AkariState({
    required this.grid,
    required this.bulbs,
    required this.lit,
    this.levelNumber = 1,
    this.isVictory = false,
    this.isLoading = true,
  });

  AkariState copyWith({
    IList<IList<int>>? grid,
    IList<IList<bool>>? bulbs,
    IList<IList<bool>>? lit,
    int? levelNumber,
    bool? isVictory,
    bool? isLoading,
  }) {
    return AkariState(
      grid: grid ?? this.grid,
      bulbs: bulbs ?? this.bulbs,
      lit: lit ?? this.lit,
      levelNumber: levelNumber ?? this.levelNumber,
      isVictory: isVictory ?? this.isVictory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class AkariNotifier extends _$AkariNotifier {
  static const String gameId = 'akari';
  Future<void> _pendingWrites = Future<void>.value();

  // Keep saves in order when the user taps quickly, restarts, or changes levels.
  void _queueSave(Future<void> Function() action) {
    _pendingWrites = _pendingWrites.then((_) => action()).catchError((Object _) {
      // Offline progress is best-effort; the game remains playable.
    });
  }

  Future<void> flushProgress() => _pendingWrites;

  @override
  AkariState build() => AkariState(
        grid: <IList<int>>[].lock,
        bulbs: <IList<bool>>[].lock,
        lit: <IList<bool>>[].lock,
      );

  void initGame() => loadLevel(
        CampaignProgress.selectedLevel(
          gameId,
          count: AkariCampaignData.levelCount,
        ),
      );

  void loadLevel(int levelNumber) => _applyLevel(levelNumber, restore: true);

  void _applyLevel(int levelNumber, {required bool restore}) {
    if (levelNumber < 1 || levelNumber > AkariCampaignData.levelCount) {
      throw RangeError.range(levelNumber, 1, AkariCampaignData.levelCount);
    }
    final grid = AkariCampaignData.board(levelNumber);
    final n = grid.length;
    final bulbs = List.generate(n, (_) => List.filled(n, false));
    if (restore) {
      final saved = CampaignProgress.loadActive(
        gameId,
        levelNumber,
        maxLength: n * n,
      );
      for (final index in saved ?? const <int>[]) {
        final row = index ~/ n;
        final col = index % n;
        if (index >= 0 && index < n * n && grid[row][col] == -2) {
          bulbs[row][col] = true;
        }
      }
    }
    final lit = AkariEngine.calculateLit(grid, bulbs);
    state = AkariState(
      grid: grid.map((row) => row.lock).toIList(),
      bulbs: bulbs.map((row) => row.lock).toIList(),
      lit: lit.map((row) => row.lock).toIList(),
      levelNumber: levelNumber,
      isLoading: false,
    );
    _queueSave(() => CampaignProgress.saveSelected(gameId, levelNumber));
  }

  void restartLevel() {
    final levelNumber = state.levelNumber;
    _queueSave(() => CampaignProgress.clearActive(gameId, levelNumber));
    _applyLevel(levelNumber, restore: false);
  }

  void toggleBulb(int r, int c) {
    if (state.isLoading || state.isVictory ||
        r < 0 || c < 0 || r >= state.grid.length ||
        c >= state.grid.length || state.grid[r][c] != -2) {
      return;
    }
    final grid = state.grid.map((row) => row.toList()).toList();
    final bulbs = state.bulbs.map((row) => row.toList()).toList();
    bulbs[r][c] = !bulbs[r][c];

    // A 5x5..7x7 grid does not need an isolate, avoiding stale async results
    // that could overwrite a newer move or a newly selected level.
    final lit = AkariEngine.calculateLit(grid, bulbs);
    final won = AkariEngine.checkVictory(grid, bulbs, lit);
    final levelNumber = state.levelNumber;
    state = state.copyWith(
      bulbs: bulbs.map((row) => row.lock).toIList(),
      lit: lit.map((row) => row.lock).toIList(),
      isVictory: won,
    );

    if (won) {
      _queueSave(() async {
        final completed = CampaignProgress.load(gameId)..add(levelNumber);
        await CampaignProgress.save(gameId, completed);
        await CampaignProgress.clearActive(gameId, levelNumber);
      });
    } else {
      final n = grid.length;
      final active = <int>[
        for (var row = 0; row < n; row++)
          for (var col = 0; col < n; col++)
            if (bulbs[row][col]) row * n + col,
      ];
      _queueSave(() => CampaignProgress.saveActive(gameId, levelNumber, active));
    }
  }
}
