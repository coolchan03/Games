import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/nim/nim_screen.dart';

void main() {
  test('Nim winner accounts for normal and misere last move', () {
    final normal = NimGame([1]);
    normal.take(0, 1);
    expect(normal.over, true);
    expect(normal.winner, 0);
    final misere = NimGame([1], misere: true);
    misere.take(0, 1);
    expect(misere.over, true);
    expect(misere.winner, 1);
  });

  test('Nim restores normal and misere positions and rejects bad saves', () {
    for (final misere in [false, true]) {
      final original = NimGame([1, 3, 5, 7], misere: misere);
      original.take(3, 2);
      final snapshot = original.snapshot();
      final restored = NimGame.restore(snapshot, misere: misere);
      expect(restored, isNotNull);
      expect(restored!.rows, original.rows);
      expect(restored.turn, 1);
      expect(restored.misere, misere);
      expect(NimGame.restore([1, 1, 3, 5, 8], misere: misere), isNull);
      expect(NimGame.restore([3, 1, 3, 5, 7], misere: misere), isNull);
    }
  });

  test('Hard Nim chooses a mathematically winning move', () {
    final game = NimGame([1, 3, 5]);
    final move = game.bestMove(Random(1), 2);
    expect(move.$2, greaterThan(0));
    expect(move.$2, lessThanOrEqualTo(game.rows[move.$1]));
    game.take(move.$1, move.$2);
    expect(game.rows.fold<int>(0, (a, b) => a ^ b), 0);
  });
}
