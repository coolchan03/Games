import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'user_providers.dart';

part 'game_session_provider.g.dart';

/// Move a launch to the front without duplicates and cap offline history.
List<String> recentlyLaunchedGames(Iterable<String> existing, String gameId,
    {int limit = 20}) {
  if (limit <= 0) return const <String>[];
  final ordered = <String>[];
  final seen = <String>{};
  for (final id in <String>[gameId, ...existing]) {
    if (id.isEmpty || !seen.add(id)) continue;
    ordered.add(id);
    if (ordered.length == limit) break;
  }
  return ordered;
}

class GameSession {
  final String? lastGameId;
  final String selectedCategory;
  final String searchQuery;
  final List<String> recentGameIds;

  GameSession({
    this.lastGameId,
    this.selectedCategory = 'ALL',
    this.searchQuery = '',
    this.recentGameIds = const <String>[],
  });

  GameSession copyWith({
    String? lastGameId,
    String? selectedCategory,
    String? searchQuery,
    List<String>? recentGameIds,
  }) {
    return GameSession(
      lastGameId: lastGameId ?? this.lastGameId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      recentGameIds: recentGameIds ?? this.recentGameIds,
    );
  }
}

@Riverpod(keepAlive: true)
class GameSessionNotifier extends _$GameSessionNotifier {
  @override
  GameSession build() {
    final recentIds = ref.read(userRepositoryProvider).getRecentGameIds();
    return GameSession(
      lastGameId: recentIds.isEmpty ? null : recentIds.first,
      recentGameIds: recentIds,
    );
  }

  void setSession({required String gameId, required String category, required String query}) {
    final recentIds = recentlyLaunchedGames(state.recentGameIds, gameId);
    state = GameSession(
      lastGameId: gameId,
      selectedCategory: category,
      searchQuery: query,
      recentGameIds: recentIds,
    );
    unawaited(ref.read(userRepositoryProvider).saveRecentGameIds(recentIds));
  }
}
