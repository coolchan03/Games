import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/word_search/word_search_engine.dart';
import 'package:puzzle/ui/features/games/word_search/word_search_provider.dart';

void main() {
  test('all 20 seeded word search levels have valid placements', () {
    final fingerprints = <String>{};
    expect(WordSearchEngine.campaignThemes.length, 20);
    expect(WordSearchEngine.campaignWordBanks.length, 20);
    for (var level = 1; level <= 20; level++) {
      final board = WordSearchEngine.generateCampaignBoard(level);
      expect(board.words.length, WordSearchEngine.wordsForLevel(level));
      expect(board.grid.length, board.size);
      expect(board.grid.every((row) => row.length == board.size), isTrue);
      expect(board.grid.expand((row) => row).every((v) => RegExp(r'^[A-Z]$').hasMatch(v)), isTrue);
      expect(board.words.map((w) => w.word).toSet().length, board.words.length);
      for (final word in board.words) {
        expect(word.positions.length, word.word.length);
        for (var i = 0; i < word.positions.length; i++) {
          final cell = word.positions[i];
          expect(board.grid[cell.y][cell.x], word.word[i]);
        }
        expect(WordSearchNotifier.matchesPlacedPath(word.positions, word.positions), isTrue);
        expect(WordSearchNotifier.matchesPlacedPath(word.positions.reversed.toList(), word.positions), isTrue);
      }
      final again = WordSearchEngine.generateCampaignBoard(level);
      final signature = board.grid.map((row) => row.join()).join('|');
      expect(again.grid.map((row) => row.join()).join('|'), signature);
      expect(fingerprints.add(signature), isTrue, reason: 'Duplicate board at level $level');
    }
  });

  test('save, reload and restart an active Word Search level', () async {
    final directory = await Directory.systemTemp.createTemp('games_word_search_');
    Hive.init(directory.path);
    await Hive.openBox('app_meta');
    final first = ProviderContainer();
    try {
      final notifier = first.read(wordSearchNotifierProvider.notifier);
      await notifier.loadLevel(1);
      final word = first.read(wordSearchNotifierProvider).board!.words.first;
      final path = word.positions;
      notifier.startSelection(path.first.x, path.first.y);
      notifier.updateSelection(path.last.x, path.last.y);
      await notifier.endSelection();
      await notifier.flushProgress();
      expect(first.read(wordSearchNotifierProvider).foundWords, contains(word.word));
      final second = ProviderContainer();
      try {
        await second.read(wordSearchNotifierProvider.notifier).initGame();
        final resumed = second.read(wordSearchNotifierProvider);
        expect(resumed.foundWords, contains(word.word));
        expect(resumed.board!.words.first.isFound, isTrue);
        await second.read(wordSearchNotifierProvider.notifier).restartLevel();
        expect(second.read(wordSearchNotifierProvider).foundWords, isEmpty);
      } finally {
        second.dispose();
      }
    } finally {
      first.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('invalid campaign levels and off-path selections are rejected', () {
    expect(() => WordSearchEngine.generateCampaignBoard(0), throwsRangeError);
    expect(() => WordSearchEngine.generateCampaignBoard(21), throwsRangeError);
    final word = WordSearchEngine.generateCampaignBoard(1).words.first;
    expect(WordSearchNotifier.matchesPlacedPath([], word.positions), isFalse);
  });
}
