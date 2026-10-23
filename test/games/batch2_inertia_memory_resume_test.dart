import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/memory_pairs/memory_pairs_screen.dart';

void main() {
  group('Inertia offline restoration', () {
    test('a moved board restores with identical gems and coordinates', () {
      final game = InertiaGame(w: 10, h: 10, random: Random(1));
      final before = game.snapshot();
      final direction = List.generate(8, (i) => i)
          .firstWhere(game.canMove);
      expect(game.move(direction), true);
      final saved = game.snapshot();
      final restored = InertiaGame.fromSnapshot(w: 10, h: 10, data: saved);
      expect(restored, isNotNull);
      expect(restored!.snapshot(), saved);
      expect(restored.moves, 1);
      expect(restored.gems, game.gems);
      expect(restored.dead, game.dead);
      expect(restored.canUndo, false,
          reason: 'new sessions start a fresh undo history');
      expect(game.canMove(-1), false);
      expect(game.canMove(8), false);
      game.undo();
      expect(game.snapshot(), before);
    });

    test('corrupt board positions, enums and gem counts are rejected', () {
      final data = InertiaGame(w: 10, h: 10, random: Random(2)).snapshot();
      expect(InertiaGame.fromSnapshot(
          w: 10, h: 10, data: [10, ...data.skip(1)]), isNull);
      expect(InertiaGame.fromSnapshot(
          w: 10, h: 10, data: [...data.take(5), 9, ...data.skip(6)]), isNull);
      expect(InertiaGame.fromSnapshot(
          w: 10, h: 10, data: data.take(data.length - 1).toList()), isNull);
      expect(InertiaGame.fromSnapshot(
          w: 10, h: 10, data: [...data.take(4), 0, ...data.skip(5)]), isNull);
    });
  });

  group('Memory Pairs offline restoration', () {
    test('cards, matched owners, turn, flips and computer memory survive', () {
      final game = MemoryGame(8, random: Random(42));
      final match = List.generate(game.cards.length, (i) => i)
          .firstWhere((i) => i != 0 && game.cards[i] == game.cards[0]);
      expect(game.flip(0), false);
      expect(game.flip(match), true);
      expect(game.resolve(), true);
      expect(game.scores, [1, 0]);
      final firstUnknown = game.hidden.first;
      expect(game.flip(firstUnknown), false);
      final saved = game.snapshot();

      final restored = MemoryGame.fromSnapshot(8, saved);
      expect(restored, isNotNull);
      expect(restored!.snapshot(), saved);
      expect(restored.scores, [1, 0]);
      expect(restored.up, [firstUnknown]);
      expect(restored.seen[firstUnknown], restored.cards[firstUnknown]);
      expect(restored.flip(firstUnknown), false,
          reason: 'cannot flip a revealed card twice');
    });

    test('corrupt cards, owners and face-up indexes are rejected', () {
      final game = MemoryGame(8, random: Random(42));
      final data = game.snapshot();
      final invalidCards = List<int>.of(data)..[5] = 23;
      expect(MemoryGame.fromSnapshot(8, invalidCards), isNull);
      final invalidOwners = List<int>.of(data)..[5 + 16] = 1;
      expect(MemoryGame.fromSnapshot(8, invalidOwners), isNull);
      final invalidUp = List<int>.of(data)
        ..[2] = 2
        ..[3] = 0
        ..[4] = 0;
      expect(MemoryGame.fromSnapshot(8, invalidUp), isNull);
      expect(MemoryGame.fromSnapshot(8, data.take(10).toList()), isNull);
    });
  });
}
