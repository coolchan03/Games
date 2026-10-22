import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../common/campaign_progress.dart';
import 'word_search_engine.dart';

part 'word_search_provider.g.dart';

class WordSearchState {
  final WordSearchBoard? board;
  final List<Point<int>> selection;
  final bool isSolved;
  final Set<String> foundWords;
  final int levelNumber;

  WordSearchState({
    this.board,
    this.selection = const [],
    this.isSolved = false,
    this.foundWords = const {},
    this.levelNumber = 1,
  });

  WordSearchState copyWith({
    WordSearchBoard? board,
    List<Point<int>>? selection,
    bool? isSolved,
    Set<String>? foundWords,
    int? levelNumber,
  }) {
    return WordSearchState(
      board: board ?? this.board,
      selection: selection ?? this.selection,
      isSolved: isSolved ?? this.isSolved,
      foundWords: foundWords ?? this.foundWords,
      levelNumber: levelNumber ?? this.levelNumber,
    );
  }
}

@riverpod
class WordSearchNotifier extends _$WordSearchNotifier {
  static const gameId = 'word_search';
  int _loadRequest = 0;
  Future<void> _pendingWrites = Future<void>.value();

  // Serialize offline writes so a restart cannot race a pending progress save.
  Future<void> _persist(Future<void> Function() action) {
    final result = _pendingWrites.then((_) => action());
    _pendingWrites = result.catchError((Object _) {});
    return result;
  }

  @override
  WordSearchState build() => WordSearchState();

  Future<void> initGame() => loadLevel(CampaignProgress.selectedLevel(
        gameId,
        count: WordSearchEngine.campaignLevelCount,
      ));

  Future<void> loadLevel(int level) async {
    RangeError.checkValueInInterval(
      level, 1, WordSearchEngine.campaignLevelCount, 'level',
    );
    final request = ++_loadRequest;
    state = WordSearchState(levelNumber: level);
    final board = await compute(WordSearchEngine.generateCampaignBoard, level);
    if (request != _loadRequest) return;
    await _persist(() => CampaignProgress.saveSelected(gameId, level));
    if (request != _loadRequest) return;
    final active = CampaignProgress.loadActive(
      gameId, level, maxLength: board.words.length,
    ) ?? <int>[];
    final restored = <int>{};
    for (final index in active) {
      if (index >= 0 && index < board.words.length && restored.add(index)) {
        board.words[index].isFound = true;
      }
    }
    state = WordSearchState(
      levelNumber: level,
      board: board,
      foundWords: {
        for (final word in board.words)
          if (word.isFound) word.word,
      },
    );
  }

  Future<void> restartLevel() async {
    final level = state.levelNumber;
    final request = ++_loadRequest;
    state = WordSearchState(levelNumber: level);
    await _persist(() => CampaignProgress.clearActive(gameId, level));
    if (request != _loadRequest) return;
    await loadLevel(level);
  }

  Future<void> flushProgress() => _pendingWrites;

  void cancelSelection() {
    if (state.selection.isNotEmpty) {
      state = state.copyWith(selection: []);
    }
  }

  void startSelection(int x, int y) {
    if (state.isSolved || state.board == null) return;
    if (x < 0 || y < 0 || x >= state.board!.size ||
        y >= state.board!.size) return;
    state = state.copyWith(selection: [Point(x, y)]);
  }

  void updateSelection(int x, int y) {
    if (state.isSolved || state.selection.isEmpty || state.board == null) {
      return;
    }
    final start = state.selection.first;
    if (start.x == x && start.y == y) return;
    if (x < 0 || y < 0 || x >= state.board!.size ||
        y >= state.board!.size) return;
    final dx = (x - start.x).abs();
    final dy = (y - start.y).abs();
    if (dx == 0 || dy == 0 || dx == dy) {
      final steps = max(dx, dy);
      final stepX = dx == 0 ? 0 : (x - start.x) ~/ dx;
      final stepY = dy == 0 ? 0 : (y - start.y) ~/ dy;
      state = state.copyWith(selection: [
        for (var i = 0; i <= steps; i++)
          Point(start.x + i * stepX, start.y + i * stepY),
      ]);
    }
  }

  /// Accept only the exact placed path, not an accidental word elsewhere.
  static bool matchesPlacedPath(
    List<Point<int>> selected, List<Point<int>> placed,
  ) {
    if (selected.length != placed.length) return false;
    var forwards = true;
    var backwards = true;
    for (var i = 0; i < selected.length; i++) {
      if (selected[i] != placed[i]) forwards = false;
      if (selected[i] != placed[placed.length - 1 - i]) backwards = false;
    }
    return forwards || backwards;
  }

  Future<void> endSelection() async {
    if (state.isSolved || state.selection.isEmpty || state.board == null) {
      return;
    }
    final board = state.board!;
    final selected = state.selection;
    var found = false;
    for (final word in board.words) {
      if (!word.isFound && matchesPlacedPath(selected, word.positions)) {
        word.isFound = true;
        found = true;
        break;
      }
    }
    if (!found) {
      state = state.copyWith(selection: []);
      return;
    }
    final foundWords = {
      for (final word in board.words)
        if (word.isFound) word.word,
    };
    final allFound = board.words.every((word) => word.isFound);
    final level = state.levelNumber;
    state = state.copyWith(
      selection: [],
      foundWords: foundWords,
      isSolved: allFound,
    );
    final activeIndices = [
      for (var i = 0; i < board.words.length; i++)
        if (board.words[i].isFound) i,
    ];
    await _persist(() async {
      if (allFound) {
        final completed = CampaignProgress.load(gameId)..add(level);
        await CampaignProgress.save(gameId, completed);
        await CampaignProgress.clearActive(gameId, level);
      } else {
        await CampaignProgress.saveActive(gameId, level, activeIndices);
      }
    });
  }
}
