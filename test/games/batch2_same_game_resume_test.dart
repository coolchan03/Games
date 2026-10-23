import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_engine.dart';

void main() {
  test('Same Game preserves removed tiles and score offline', () {
    final game = SameGame(w: 6, h: 6, colours: 3, random: Random(42));
    final move = List.generate(game.grid.length, (i) => i)
        .firstWhere((i) => game.group(i).length >= 2);
    expect(game.remove(move), true);
    final data = game.snapshot();
    final saved = SameGame(w: 6, h: 6, colours: 3, random: Random(12));
    expect(saved.restore(data), true);
    expect(saved.snapshot(), data);
    expect(saved.restore([0, ...List.filled(36, 9)]), false);
    expect(saved.snapshot(), data);
    game.undo();
    expect(game.canUndo, false);
  });
}
