import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/data/game_guides_complete.dart';

void main() {
  test('every catalog game has a meaningful rules and controls guide', () {
    for (final meta in allGamesMetadata) {
      final guide = guideForGame(meta.id);
      expect(guide, isNotNull, reason: meta.id);
      expect(guide!.objective.length, greaterThan(25), reason: meta.id);
      expect(guide.controls.length, greaterThan(15), reason: meta.id);
      expect(guide.walkthrough, isNotEmpty, reason: meta.id);
      expect(guide.strategies, isNotEmpty, reason: meta.id);
      expect(guide.objective, isNot(contains('Guide not found')),
          reason: meta.id);
    }
  });

  test('newer games have game-specific instructions, not generic filler', () {
    expect(guideForGame('dice_421')!.objective, contains('charge'));
    expect(guideForGame('kings_corner')!.objective.toLowerCase(),
        contains('king'));
    expect(guideForGame('mahjong_solitaire')!.objective.toLowerCase(),
        contains('tile'));
    expect(guideForGame('chess')!.objective.toLowerCase(), contains('chess'));
  });

  test('unknown game does not invent a guide', () {
    expect(guideForGame('not-a-real-game'), isNull);
  });
}
