import '../../../data/game_metadata.dart';

/// Non-destructive view of the catalog for the small-screen browser.
List<GameMetadata> selectMenuGames(
  List<GameMetadata> games, {
  required Set<String> favorites,
  required bool favoritesOnly,
  required bool alphabetical,
  required Map<String, String> titles,
}) {
  final selected = [
    for (final game in games)
      if (!favoritesOnly || favorites.contains(game.id)) game,
  ];
  if (alphabetical) {
    String display(GameMetadata game) => (titles[game.id] ?? game.id).toLowerCase();
    selected.sort((a, b) {
      final byName = display(a).compareTo(display(b));
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
  }
  return selected;
}
