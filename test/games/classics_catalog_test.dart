import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_engine.dart';

void main() {
  test('priority classics are available through the shared catalog', () {
    final ids = allGamesMetadata.map((game) => game.id).toSet();
    expect(ids, containsAll(['chess', 'texas_holdem', 'five_card_draw']));
  });

  test('casebook offers at least nine original solver-verified cases', () {
    expect(DetectiveCasebook.cases.length, greaterThanOrEqualTo(9));
    for (final game in DetectiveCasebook.cases) {
      expect(game.countSolutions(), 1, reason: game.id);
    }
  });
}
