import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/home/game_browse_order.dart';
import 'package:puzzle/ui/features/home/widgets/game_guide_fallback.dart';

void main() {
  test('alphabetic order sorts visible titles without modifying provider order', () {
    final source = <GameMetadata>[
      allGamesMetadata.firstWhere((g) => g.id == 'kings_corner'),
      allGamesMetadata.firstWhere((g) => g.id == 'four_two_one'),
      allGamesMetadata.firstWhere((g) => g.id == 'petits_chevaux'),
    ];
    final sorted = orderGameCatalog(source, {
      'kings_corner': "King's Corner",
      'four_two_one': '421',
      'petits_chevaux': 'Petits Chevaux',
    }, alphabetically: true);
    expect(sorted.map((g) => g.id), [
      'four_two_one', 'kings_corner', 'petits_chevaux',
    ]);
    expect(source.first.id, 'kings_corner');
    expect(orderGameCatalog(source, {}, alphabetically: false), source);
  });

  test('every registered game has a usable guide without empty placeholders', () {
    for (final game in allGamesMetadata) {
      final guide = guideForGame(game);
      expect(guide.title, isNotEmpty, reason: game.id);
      expect(guide.objective, isNotEmpty, reason: game.id);
      expect(guide.controls, isNotEmpty, reason: game.id);
      expect(guide.walkthrough, isNotEmpty, reason: game.id);
    }
  });

  testWidgets('the catalog guide gives a real play path to a new game', (tester) async {
    final game = allGamesMetadata.firstWhere((g) => g.id == 'four_two_one');
    final guide = guideForGame(game);
    expect(guide.title, '421');
    expect(guide.controls, contains('Hold'));
    expect(guide.walkthrough.join(' '), contains('Roll'));
  });
}
