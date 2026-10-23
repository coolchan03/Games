import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:puzzle/ui/features/games/tower_of_hanoi/tower_of_hanoi_screen.dart';

void main() {
  group('Signpost', () {
    test('only a fully linked valid path counts as solved', () {
      final p = SignpostPuzzle(w: 4, h: 4, random: Random(12));
      final game = SignpostGame(p);
      // The displayed clue numbers cannot solve a board on their own.
      p.clues
        ..clear()
        ..addEntries([
          for (var k = 0; k < p.n; k++) MapEntry(p.solution[k], k),
        ]);
      expect(game.solved, false);
      for (var k = 0; k + 1 < p.n; k++) {
        game.link(p.solution[k], p.solution[k + 1]);
      }
      expect(game.solved, true);
      game.unlink(p.solution[2]);
      expect(game.solved, false);
      game.undo();
      expect(game.solved, true);
    });

    test('rejects cycles, duplicate incoming edges and corrupt saves', () {
      final p = SignpostPuzzle(w: 4, h: 4, random: Random(19));
      final a = p.solution[1], b = p.solution[2];
      p.clues
        ..clear()
        ..[p.solution.first] = 0
        ..[p.solution.last] = p.n - 1;
      p.arrows[b] = p.dirBetween(b, a)!;
      final game = SignpostGame(p);
      expect(game.canLink(a, b), true);
      game.link(a, b);
      expect(game.canLink(b, a), false, reason: 'a link must not close a cycle');
      final snapshot = game.snapshot();
      final restored = SignpostGame(p);
      expect(restored.restore(snapshot), true);
      expect(restored.snapshot(), snapshot);
      expect(restored.restore([p.n + 4, ...snapshot.skip(1)]), false);
      expect(restored.snapshot(), snapshot,
          reason: 'invalid restoration leaves earlier board unchanged');
    });

    test('stored puzzle seed regenerates identical geometry', () {
      final first = SignpostPuzzle(w: 4, h: 4, random: Random(123456));
      final second = SignpostPuzzle(w: 4, h: 4, random: Random(123456));
      expect(second.solution, first.solution);
      expect(second.arrows, first.arrows);
      expect(second.clues, first.clues);
    });
  });

  group('Peg Solitaire', () {
    test('valid moves survive offline snapshots, corrupt holes are rejected', () {
      for (final european in [false, true]) {
        final game = PegBoard(european: european);
        final from = List.generate(49, (i) => i)
            .firstWhere((i) => game.holes[i] && game.targets(i).isNotEmpty);
        final to = game.targets(from).first;
        expect(game.move(from, to), true);
        final snapshot = game.snapshot();
        final restored = PegBoard(european: european);
        expect(restored.restore(snapshot), true);
        expect(restored.snapshot(), snapshot);
        expect(restored.remaining, game.remaining);
        expect(restored.history, isEmpty);
        final impossible = List<int>.of(snapshot);
        impossible[0] = 1;
        expect(restored.restore(impossible), false);
        expect(restored.snapshot(), snapshot);
        game.undo();
        expect(game.remaining, european ? 36 : 32);
      }
    });
  });

  group('Tower of Hanoi', () {
    test('legal moves, undo, and snapshots retain the complete arrangement', () {
      final game = HanoiGame(4);
      expect(game.optimal, 15);
      expect(game.move(0, 2), true);
      expect(game.move(0, 2), false, reason: 'larger onto smaller forbidden');
      expect(game.move(0, 1), true);
      final snapshot = game.snapshot();
      final restored = HanoiGame(4);
      expect(restored.restore(snapshot), true);
      expect(restored.snapshot(), snapshot);
      expect(restored.canUndo, false);
      final suggested = restored.hint();
      expect(suggested, isNotNull);
      expect(restored.canMove(suggested!.$1, suggested.$2), true);
      expect(restored.restore([0, 0, 0]), false);
      expect(restored.snapshot(), snapshot);
      game.undo();
      expect(game.moves, 1);
      expect(game.pegs[0], [4, 3, 2]);
    });
  });
}
