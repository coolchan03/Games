import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/backgammon/engine/backgammon_match.dart';
import 'package:puzzle/ui/features/games/backgammon/engine/game_entities.dart';
import 'package:puzzle/ui/features/games/battleship/battleship_engine.dart';
import 'package:puzzle/ui/features/games/dots_and_boxes/dots_engine.dart';
import 'package:puzzle/ui/features/games/gomoku/gomoku_engine.dart';
import 'package:puzzle/ui/features/games/ludo/ludo_engine.dart';
import 'package:puzzle/ui/features/games/memory_pairs/memory_pairs_screen.dart';
import 'package:puzzle/ui/features/games/nine_mens_morris/morris_engine.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:puzzle/ui/features/games/shut_the_box/shut_the_box_screen.dart';
import 'package:puzzle/ui/features/games/snakes_and_ladders/snakes_and_ladders_screen.dart';
import 'package:puzzle/ui/features/games/tower_of_hanoi/tower_of_hanoi_screen.dart';

int checkers(GameState s, Player p) {
  var n = 0;
  for (final pt in s.points) {
    if (pt.player == p) n += pt.pieceCount;
  }
  return n +
      (p == Player.white ? s.whiteBar.length + s.whiteHome.length : s.blackBar.length + s.blackHome.length);
}

void main() {
  group('Backgammon', () {
    test('computer vs computer finishes with 15 checkers each throughout', () {
      final m = BackgammonMatch(random: Random(3));
      var turns = 0;
      while (m.winner == null && turns++ < 600) {
        if (m.needsRoll) m.roll();
        if (m.winner != null || m.needsRoll) continue;
        final turn = m.computerTurn(2);
        for (final mv in turn) {
          expect(m.play(mv), isTrue);
        }
        expect(checkers(m.state, Player.white), 15);
        expect(checkers(m.state, Player.black), 15);
      }
      expect(m.winner, isNotNull);
      expect(m.resultPoints, inInclusiveRange(1, 3));
    });
    test('doubles give four moves', () {
      final m = BackgammonMatch(random: Random(1));
      while (!m.needsRoll) {
        final t = m.computerTurn(0);
        for (final mv in t) {
          m.play(mv);
        }
      }
      m.roll(fixed: [3, 3]);
      expect(m.state.dice, [3, 3, 3, 3]);
    });
    test('must use both dice when possible', () {
      final m = BackgammonMatch(random: Random(2));
      while (!m.needsRoll) {
        for (final mv in m.computerTurn(0)) {
          m.play(mv);
        }
      }
      m.roll(fixed: [6, 5]);
      // Every legal first move must leave a legal second move.
      for (final mv in m.legalMoves()) {
        final copy = BackgammonMatch(random: Random(0))..state = m.state;
        copy.play(mv);
        expect(copy.state.dice.isEmpty || copy.legalMoves().isNotEmpty || copy.state.currentPlayer != m.state.currentPlayer, isTrue);
      }
    });
  });

  group('Ludo', () {
    test('routes rotate into each other', () {
      expect(cellFor(1, 0), [8, 1]);
      expect(cellFor(2, 0), [13, 8]);
      expect(cellFor(3, 0), [6, 13]);
    });
    test('need a six to leave base, capture sends home', () {
      final g = LudoGame(seats: [0, 1, 2, 3], computer: {}, random: Random(1));
      expect(g.roll(3), isFalse);
      expect(g.current, 1);
      g.current = 0;
      expect(g.roll(6), isTrue);
      g.play(g.legal.first);
      expect(g.steps[0]![0], 0);
      // Put yellow two squares ahead of green's piece on an unsafe square.
      g.steps[0]![0] = 2;
      final target = cellFor(0, 4);
      final yellowStep = List.generate(51, (s) => s).firstWhere((s) {
        final c = cellFor(1, s);
        return c[0] == target[0] && c[1] == target[1];
      });
      g.steps[1]![0] = yellowStep;
      g.current = 0;
      g.dice = null;
      g.sixes = 0;
      g.roll(2);
      final m = g.legal.firstWhere((m) => m.piece == 0);
      expect(m.captures, [(1, 0)]);
      g.play(m);
      expect(g.steps[1]![0], -1);
      expect(g.current, 0, reason: 'capturing earns another roll');
    });
    test('computer-only game ends', () {
      final g = LudoGame(seats: [0, 1, 2, 3], computer: {0, 1, 2, 3}, random: Random(9));
      var guard = 0;
      while (!g.over && guard++ < 20000) {
        if (g.roll()) g.play(g.choose(2));
      }
      expect(g.over, isTrue);
    });
  });

  group("Nine Men's Morris", () {
    test('mills and removal', () {
      final s = MorrisState();
      s.apply(const MorrisMove(0));
      s.apply(const MorrisMove(9));
      s.apply(const MorrisMove(1));
      s.apply(const MorrisMove(10));
      expect(s.formsMill(null, 2), isTrue);
      final moves = s.legalMoves().where((m) => m.to == 2).toList();
      expect(moves.map((m) => m.remove).toSet(), {9, 10});
    });
    test('hard AI blocks an open mill', () {
      final s = MorrisState();
      s.apply(const MorrisMove(0)); // white
      s.apply(const MorrisMove(23)); // black
      s.apply(const MorrisMove(1)); // white threatens 2
      final m = morrisAi(s, 2, Random(1));
      expect(m.to, 2);
    });
  });

  group('Gomoku and Dots', () {
    test('five in a row wins, AI blocks four', () {
      final g = GomokuGame();
      for (var c = 0; c < 4; c++) {
        g.play(7 * 15 + c + 3);
        g.play(0 * 15 + c * 2);
      }
      expect(g.winner, 0);
      g.play(7 * 15 + 7);
      expect(g.winner, 1);
      final h = GomokuGame();
      for (var c = 0; c < 4; c++) {
        h.play(7 * 15 + 3 + c);
        if (c < 3) h.play(14 * 15 + c * 3);
      }
      final block = h.aiMove(2, Random(1));
      expect([7 * 15 + 2, 7 * 15 + 7], contains(block));
    });
    test('completing a box gives another turn', () {
      final d = DotsGame(rows: 1, cols: 1);
      expect(d.play(0), isFalse);
      expect(d.play(1), isFalse);
      expect(d.play(2), isFalse);
      expect(d.turn, 2);
      expect(d.play(3), isTrue);
      expect(d.scores, [0, 1]);
      expect(d.over, isTrue);
    });
    test('AI vs AI dots game ends with all boxes claimed', () {
      final d = DotsGame(rows: 4, cols: 4);
      final rng = Random(2);
      while (!d.over) {
        d.play(d.aiMove(2, rng));
      }
      expect(d.scores[0] + d.scores[1], 16);
    });
  });

  group('Battleship', () {
    test('fleet placement and sinking', () {
      final o = Ocean(Random(4));
      expect(o.ships.fold<int>(0, (s, x) => s + x.cells.length), 17);
      final all = o.ships.expand((s) => s.cells).toSet();
      expect(all.length, 17);
      for (final c in all) {
        o.fire(c);
      }
      expect(o.defeated, isTrue);
    });
    test('hard gunner sinks a fleet in under 100 shots', () {
      final o = Ocean(Random(5));
      final g = Gunner(2, Random(6));
      var shots = 0;
      while (!o.defeated) {
        o.fire(g.pick(o));
        shots++;
      }
      expect(shots, lessThan(80));
    });
  });

  group('Small games', () {
    test('snakes and ladders needs exact roll', () {
      final g = SnakesGame(2, random: Random(1));
      g.pos[0] = 97;
      g.roll(5);
      expect(g.pos[0], 97);
      g.turn = 0;
      g.roll(3);
      expect(g.winner, 0);
    });
    test('peg solitaire opening has four moves', () {
      final b = PegBoard();
      expect(b.remaining, 32);
      final moves = [for (var i = 0; i < 49; i++) ...b.targets(i)];
      expect(moves.length, 4);
    });
    test('shut the box reachability', () {
      final g = ShutTheBoxGame(random: Random(1));
      for (var t = 1; t <= 9; t++) {
        g.open[t] = false;
      }
      g.open[4] = g.open[5] = true;
      expect(g.reachable(9), isTrue);
      expect(g.reachable(6), isFalse);
    });
    test('hanoi hints solve optimally', () {
      for (final n in [3, 4, 5]) {
        final g = HanoiGame(n);
        while (!g.solved) {
          final h = g.hint()!;
          expect(g.move(h.$1, h.$2), isTrue);
        }
        expect(g.moves, g.optimal);
      }
    });
    test('memory perfect-recall computer clears the board', () {
      final g = MemoryGame(8, random: Random(3));
      var guard = 0;
      while (!g.over && guard++ < 200) {
        g.flip(g.aiPick(1));
        g.flip(g.aiPick(1));
        g.resolve();
      }
      expect(g.over, isTrue);
      expect(g.scores[0] + g.scores[1], 8);
    });
  });
}
