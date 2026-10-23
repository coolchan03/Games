import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/sixteen/sixteen_screen.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_screen.dart';
import 'package:puzzle/ui/features/games/black_box/black_box_engine.dart';

void main() {
  test('Sixteen roundtrip, undo and malformed snapshot handling', () {
    for (final n in [3, 4, 5]) {
      final game = SixteenGame(n: n, random: Random(11));
      final before = game.snapshot();
      game.shiftRow(0, 1);
      expect(game.canUndo, true);
      final after = game.snapshot();
      final restored = SixteenGame(n: n, random: Random(12));
      expect(restored.restore(after), true);
      expect(restored.snapshot(), after);
      expect(restored.restore([0, ...List.filled(n * n, 1)]), false);
      expect(restored.snapshot(), after);
      game.undo();
      expect(game.snapshot(), before);
    }
  });

  test('Twiddle roundtrip, undo and malformed snapshot handling', () {
    for (final (n, block) in [(3, 2), (4, 2), (4, 3), (5, 3)]) {
      final game = TwiddleGame(n: n, block: block, random: Random(11));
      final before = game.snapshot();
      game.rotate(0, 0, true);
      final after = game.snapshot();
      final restored = TwiddleGame(n: n, block: block, random: Random(12));
      expect(restored.restore(after), true);
      expect(restored.snapshot(), after);
      expect(restored.restore([0, ...List.filled(n * n, 1)]), false);
      expect(restored.snapshot(), after);
      game.undo();
      expect(game.snapshot(), before);
    }
  });

  test('Black Box saves all laser exits and marked balls', () {
    final original = BlackBoxGame(n: 8, balls: 4, random: Random(7));
    original.fire(1);
    original.fire(15);
    for (final cell in original.hidden) {
      original.toggleGuess(cell);
    }
    original.revealed = true;
    final data = original.snapshot();
    final restored = BlackBoxGame.fromSnapshot(n: 8, balls: 4, data: data);
    expect(restored, isNotNull);
    expect(restored!.snapshot(), data);
    expect(restored.score, original.score);
    expect(restored.correct, true);
    expect(BlackBoxGame.fromSnapshot(
      n: 8, balls: 4, data: [2, ...data.skip(1)],
    ), isNull);
    expect(BlackBoxGame.fromSnapshot(
      n: 8, balls: 4, data: data.skip(1).toList(),
    ), isNull);
  });
}
