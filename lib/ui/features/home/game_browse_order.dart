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
