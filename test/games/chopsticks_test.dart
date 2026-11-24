import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/ui/features/games/chopsticks/chopsticks_screen.dart';
import 'package:puzzle/ui/features/games/chopsticks/chopsticks_engine.dart';

void main() {
  for (final rollover in [false, true]) {
    group(rollover ? 'rollover' : 'classic', () {
      final solver = ChopsticksSolver(rollover);

      test('attack and split rules', () {
        final s = ChopsticksState([1, 1], [1, 1], 0, rollover: rollover);
        final after = s.apply(const ChopsticksMove.attack(0, 0));
        expect(after.hands[1], [2, 1]);
        expect(after.turn, 1);
        // 4 + 1 = 5: out in classic, wraps to 0 either way (5 % 5).
        final big = ChopsticksState([4, 0], [1, 2], 0, rollover: rollover);
        expect(big.apply(const ChopsticksMove.attack(0, 0)).hands[1][0], 0);
        // 4 + 2 = 6: out in classic, 1 with rollover.
        expect(big.apply(const ChopsticksMove.attack(0, 1)).hands[1][1],
            rollover ? 1 : 0);
        // Splits conserve fingers and never repeat the current layout.
        final sp = ChopsticksState([4, 0], [1, 1], 0, rollover: rollover);
        for (final m in sp.legalMoves().where((m) => m.isSplit)) {
          final n = sp.apply(m);
          expect(n.total(0), 4);
          expect(([...n.hands[0]]..sort()), isNot([0, 4]));
        }
        // Dead hands cannot attack or be attacked.
        final dead = ChopsticksState([0, 3], [2, 0], 0, rollover: rollover);
        expect(dead.legalMoves().where((m) => !m.isSplit).toList(),
            [const ChopsticksMove.attack(1, 0)]);
      });

      test('terminal positions', () {
        final won = ChopsticksState([2, 0], [0, 0], 1, rollover: rollover);
        expect(won.over, isTrue);
        expect(won.winner, 0);
        expect(won.legalMoves(), isEmpty);
      });

      test('solution is self-consistent', () {
        // Every forced win has a move into a position lost one ply shorter;
        // every forced loss has only winning replies.
        final seen = <String>{};
        void walk(ChopsticksState s) {
          if (!seen.add(s.key) || s.over) return;
          final v = solver.valueOf(s);
          final next = [for (final m in s.legalMoves()) s.apply(m)];
          if (v > 0) {
            // Lost in v-1 plies; a finished game counts as 0 plies.
            expect(
                next.any((n) => (n.over ? 0 : -solver.valueOf(n)) == v - 1),
                isTrue,
                reason: s.key);
          } else if (v < 0) {
            expect(next.every((n) => solver.valueOf(n) > 0), isTrue, reason: s.key);
          } else {
            expect(next.any((n) => solver.valueOf(n) < 0), isFalse, reason: s.key);
            expect(next.any((n) => n.over && n.isOut(n.turn)), isFalse, reason: s.key);
          }
          next.forEach(walk);
        }
        walk(ChopsticksState.start(rollover: rollover));
        expect(seen.length, greaterThan(50));
      });

      test('perfect play never loses a won position to random play', () {
        final random = Random(3);
        var perfectWins = 0, games = 0;
        for (var g = 0; g < 200; g++) {
          var s = ChopsticksState.start(rollover: rollover);
          final perfectSide = g % 2;
          for (var ply = 0; ply < 200 && !s.over; ply++) {
            final m = s.turn == perfectSide
                ? solver.bestMove(s)!
                : solver.randomMove(s, random)!;
            s = s.apply(m);
          }
          games++;
          if (s.winner == perfectSide) perfectWins++;
          if (!s.over) continue; // a draw cycle is allowed against a random side
          // A perfect side only loses if the start was lost for it.
          if (s.winner != perfectSide) {
            expect(solver.valueOf(ChopsticksState.start(rollover: rollover)) <= 0 || perfectSide == 1,
                isTrue);
          }
        }
        expect(perfectWins, greaterThan(games ~/ 2));
      });
    });
  }

  test('is registered exactly once', () {
    expect(allGamesMetadata.where((g) => g.id == 'chopsticks'), hasLength(1));
  });

  testWidgets('plays a turn on a phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChopsticksScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('You hand 1, 1 fingers'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Computer hand 1, 1 fingers'));
    await tester.pump();
    expect(find.text('Computer is thinking…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Split'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
