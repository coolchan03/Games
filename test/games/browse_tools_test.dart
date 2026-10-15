import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/home/game_browse_order.dart';
import 'package:puzzle/ui/features/home/widgets/game_guide_fallback.dart';

void main() {
  test('alphabetic order sorts titles without changing the featured list', () {
    final source = <GameMetadata>[
      allGamesMetadata.firstWhere((g) => g.id == 'kings_corner'),
      allGamesMetadata.firstWhere((g) => g.id == 'petits_chevaux'),
      allGamesMetadata.firstWhere((g) => g.id == 'chess'),
    ];
    final sorted = orderGameCatalog(source, {
      'kings_corner': "King's Corner",
      'petits_chevaux': 'Petits Chevaux',
      'chess': 'Chess',
    }, alphabetically: true);
    expect(sorted.map((g) => g.id), [
      'chess', 'kings_corner', 'petits_chevaux',
    ]);
    expect(source.first.id, 'kings_corner');
    expect(orderGameCatalog(source, {}, alphabetically: false), source);
  });

  test('every registered title opens a nonempty guide', () {
    for (final game in allGamesMetadata) {
      final guide = guideForGame(game);
      expect(guide.title, isNotEmpty, reason: game.id);
      expect(guide.objective, isNotEmpty, reason: game.id);
      expect(guide.controls, isNotEmpty, reason: game.id);
      expect(guide.walkthrough, isNotEmpty, reason: game.id);
    }
  });

  test('Petits Chevaux guide describes phone controls and winning', () {
    final game = allGamesMetadata.firstWhere((g) => g.id == 'petits_chevaux');
    final guide = guideForGame(game);
    expect(guide.title, 'Petits Chevaux');
    expect(guide.controls.toLowerCase(), contains('horse'));
    expect(guide.walkthrough.join(' '), contains('Roll'));
    expect(guide.objective, contains('four horses'));
  });
}
