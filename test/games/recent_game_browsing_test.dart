import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/providers/game_session_provider.dart';
import 'package:puzzle/ui/features/home/game_browse_order.dart';

void main() {
  test('recent launches are unique, newest first and bounded', () {
    expect(recentlyLaunchedGames(['chess', 'go_game'], 'go_game'),
        ['go_game', 'chess']);
    expect(recentlyLaunchedGames(['chess', 'chess', 'go_game'], 'sudoku'),
        ['sudoku', 'chess', 'go_game']);
    expect(recentlyLaunchedGames(['a', 'b', 'c'], 'z', limit: 2),
        ['z', 'a']);
    expect(recentlyLaunchedGames(['a', 'b'], 'z', limit: 0), isEmpty);
  });

  test('game session copy preserves recent history', () {
    final session = GameSession(
      lastGameId: 'chess',
      recentGameIds: ['chess', 'checkers'],
    );
    expect(session.copyWith(searchQuery: 'ches').recentGameIds,
        ['chess', 'checkers']);
  });

  test('library quick filters preserve upstream category/search results', () {
    final games = allGamesMetadata.take(4).toList();
    expect(games.length, 4);
    final favorites = subsetGameCatalog(
      games,
      subset: GameBrowseSubset.favorites,
      favoriteIds: [games[2].id, 'hidden_not_in_results'],
      recentGameIds: const [],
    );
    expect(favorites.map((game) => game.id), [games[2].id]);

    final recent = subsetGameCatalog(
      games,
      subset: GameBrowseSubset.recent,
      favoriteIds: const [],
      recentGameIds: [games[3].id, games[1].id, 'hidden_not_in_results'],
    );
    expect(recent.map((game) => game.id),
        [games[3].id, games[1].id]);

    final all = subsetGameCatalog(
      games,
      subset: GameBrowseSubset.all,
      favoriteIds: const [],
      recentGameIds: const [],
    );
    expect(all.length, 4);
  });

  test('recent games persist when the offline Hive box is reopened',
      () async {
    final temp = await Directory.systemTemp.createTemp('games-recent-test-');
    try {
      Hive.init(temp.path);
      await Hive.openBox('app_meta');
      final repository = UserRepository();
      expect(repository.getRecentGameIds(), isEmpty);
      await repository.saveRecentGameIds(['chess', 'checkers']);
      expect(repository.getRecentGameIds(), ['chess', 'checkers']);

      await Hive.box('app_meta').close();
      await Hive.openBox('app_meta');
      expect(UserRepository().getRecentGameIds(), ['chess', 'checkers']);
    } finally {
      await Hive.close();
      await temp.delete(recursive: true);
    }
  });
}
