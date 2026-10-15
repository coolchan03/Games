import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/home/game_menu_selection.dart';

void main() {
  final sample = [
    allGamesMetadata.firstWhere((g) => g.id == 'chess'),
    allGamesMetadata.firstWhere((g) => g.id == 'dice_421'),
    allGamesMetadata.firstWhere((g) => g.id == 'mahjong_solitaire'),
  ];

  test('favorites-only selection never hides games permanently', () {
    final filtered = selectMenuGames(sample,
        favorites: {'chess'}, favoritesOnly: true,
        alphabetical: false, titles: {});
    expect(filtered.map((g) => g.id), ['chess']);
    expect(sample.length, 3);
    expect(selectMenuGames(sample, favorites: {'chess'},
        favoritesOnly: false, alphabetical: false, titles: {}).length, 3);
  });

  test('alphabetical selection uses visible game titles', () {
    final ordered = selectMenuGames(sample, favorites: {},
        favoritesOnly: false, alphabetical: true,
        titles: {'chess': 'Zebra', 'dice_421': 'Apples',
            'mahjong_solitaire': 'Mango'});
    expect(ordered.map((g) => g.id),
        ['dice_421', 'mahjong_solitaire', 'chess']);
  });
}
