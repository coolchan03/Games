import 'package:puzzle/data/game_metadata.dart';

/// An optional alphabetical view of the already filtered game library.
/// Keeps the provider's curated featured/favorites order when not selected.
List<GameMetadata> orderGameCatalog(
  List<GameMetadata> games,
  Map<String, String> localizedTitles, {
  required bool alphabetically,
}) {
  if (!alphabetically) return games;
  final sorted = List<GameMetadata>.from(games);
  String title(GameMetadata game) =>
      (localizedTitles[game.id] ?? game.id.replaceAll('_', ' ')).toLowerCase();
  sorted.sort((a, b) {
    final compare = title(a).compareTo(title(b));
    return compare != 0 ? compare : a.id.compareTo(b.id);
  });
  return sorted;
}

/// Optional fast filters applied after search, category and hidden-game rules.
enum GameBrowseSubset { all, favorites, recent }

List<GameMetadata> subsetGameCatalog(
  List<GameMetadata> games, {
  required GameBrowseSubset subset,
  required Iterable<String> favoriteIds,
  required List<String> recentGameIds,
}) {
  if (subset == GameBrowseSubset.all) return games;
  if (subset == GameBrowseSubset.favorites) {
    final favorites = favoriteIds.toSet();
    return games.where((game) => favorites.contains(game.id)).toList();
  }
  final recentOrder = <String, int>{};
  for (final id in recentGameIds) {
    recentOrder.putIfAbsent(id, () => recentOrder.length);
  }
  final recent = games.where((game) => recentOrder.containsKey(game.id))
      .toList();
  recent.sort((a, b) => recentOrder[a.id]!.compareTo(recentOrder[b.id]!));
  return recent;
}
