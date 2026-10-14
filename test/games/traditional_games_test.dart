import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/aces_up/aces_up_screen.dart';
import 'package:puzzle/ui/features/games/alquerque/alquerque_engine.dart';
import 'package:puzzle/ui/features/games/bagh_chal/bagh_chal_engine.dart';
import 'package:puzzle/ui/features/games/chinese_checkers/chinese_checkers_engine.dart';
import 'package:puzzle/ui/features/games/common/cards/card.dart';
import 'package:puzzle/ui/features/games/forty_thieves/forty_thieves_engine.dart';
import 'package:puzzle/ui/features/games/neutron/neutron_engine.dart';
import 'package:puzzle/ui/features/games/poker_squares/poker_squares_screen.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_engine.dart';

/// Breadth-first Sokoban solver (push count not optimised).
bool solvable(SokobanLevel l, {int limit = 400000}) {
  String key(Set<int> boxes, int player) {
    // Normalise player to the smallest reachable cell.
    final seen = {player};
    final q = [player];
    for (var k = 0; k < q.length; k++) {
      for (final (dx, dy) in SokobanLevel.dirs) {
        final n = q[k] + dy * l.w + dx;
        if (!l.walls.contains(n) && !boxes.contains(n) && seen.add(n)) q.add(n);
      }
    }
    final b = boxes.toList()..sort();
    return '${b.join(',')}|${seen.reduce(min)}';
  }

  final start = (Set<int>.of(l.boxes), l.player);
  final visited = {key(start.$1, start.$2)};
  final queue = [start];
  for (var k = 0; k < queue.length && k < limit; k++) {
    final (boxes, player) = queue[k];
    if (boxes.difference(l.goals).isEmpty) return true;
    // Reachable cells.
    final reach = {player};
    final q = [player];
    for (var i = 0; i < q.length; i++) {
      for (final (dx, dy) in SokobanLevel.dirs) {
        final n = q[i] + dy * l.w + dx;
        if (!l.walls.contains(n) && !boxes.contains(n) && reach.add(n)) q.add(n);
      }
    }
    for (final b in boxes) {
      for (final (dx, dy) in SokobanLevel.dirs) {
        final stand = b - dy * l.w - dx, dest = b + dy * l.w + dx;
        if (!reach.contains(stand) || l.walls.contains(dest) || boxes.contains(dest)) continue;
        final nb = Set<int>.of(boxes)
          ..remove(b)
          ..add(dest);
        if (visited.add(key(nb, b))) queue.add((nb, b));
      }
    }
  }
  return false;
}

void main() {
  group('Bagh Chal', () {
    test('tigers capture by jumping and goats place first', () {
      final s = BaghState();
      expect(s.moves().length, 21);
      s.apply(const BaghMove(1)); // goat next to the tiger at 0
      final tigerMoves = s.moves();
      expect(tigerMoves.any((m) => m.capture == 1 && m.to == 2), isTrue);
    });
    test('computer vs computer finishes', () {
      final s = BaghState();
      final rng = Random(1);
      var guard = 0;
      while (s.result == 0 && guard++ < 400) {
        s.apply(baghAi(s, 1, rng));
      }
      expect(s.result, isNot(0));
    });
  });

  group('Alquerque', () {
    test('12 pieces each and only the centre empty', () {
      final s = AlquerqueState();
      expect(s.count(1), 12);
      expect(s.count(2), 12);
      expect(s.cells[12], 0);
    });
    test('captures are compulsory and chain', () {
      final s = AlquerqueState();
      s.cells.fillRange(0, 25, 0);
      s.cells[20] = 1; // (0,4)
      s.cells[15] = 2; // (0,3)
      s.cells[5] = 2; // (0,1)
      final moves = s.moves();
      expect(moves.length, 1);
      expect(moves.first.captured, [15, 5]);
    });
    test('bot game ends', () {
      final s = AlquerqueState();
      final rng = Random(3);
      var guard = 0;
      while (s.result == 0 && guard++ < 300) {
        s.apply(alquerqueAi(s, 1, rng));
      }
      expect(guard, lessThan(301));
    });
  });

  group('Neutron', () {
    test('first move skips the neutron; pieces slide to the end', () {
      final s = NeutronState();
      final moves = s.moves();
      expect(moves.every((m) => m.neutronTo == null), isTrue);
      // Bottom-left piece sliding straight up stops below the top row's piece.
      expect(moves.any((m) => m.from == 20 && m.to == 5), isTrue);
    });
    test('computer game ends', () {
      final s = NeutronState();
      final rng = Random(4);
      var guard = 0;
      while (s.result == 0 && guard++ < 200) {
        s.apply(neutronAi(s, 1, rng));
      }
      expect(s.result, isNot(0));
    });
  });

  group('Chinese Checkers', () {
    test('star has 121 holes, 10 per corner', () {
      final g = ChineseCheckers(players: 6);
      expect(g.holes.length, 121);
      for (var p = 0; p < 6; p++) {
        expect(g.owner.values.where((v) => v == p).length, 10);
      }
    });
    test('hops chain and bots reach the far corner', () {
      final g = ChineseCheckers(players: 2, random: Random(5));
      var guard = 0;
      while (g.winner == null && guard++ < 2000) {
        final (f, t) = g.aiMove(2);
        g.move(f, t);
      }
      expect(g.winner, isNotNull);
    });
  });

  group('Card patience', () {
    test('poker squares scoring', () {
      expect(scoreLine(PlayingCard.cardsFromString('AS KS QS JS TS')), 100);
      expect(scoreLine(PlayingCard.cardsFromString('2C 2D 2H 9S 9C')), 25);
      final g = PokerSquaresGame(random: Random(1));
      for (var i = 0; i < 25; i++) {
        expect(g.place(i), isTrue);
      }
      expect(g.over, isTrue);
      expect(g.total, greaterThanOrEqualTo(0));
    });
    test('aces up discards lower cards of the same suit', () {
      final g = AcesUpGame(random: Random(2));
      for (final p in g.piles) {
        p.clear();
      }
      g.piles[0].add(PlayingCard(Rank.five, Suit.hearts));
      g.piles[1].add(PlayingCard(Rank.king, Suit.hearts));
      expect(g.canDiscard(0), isTrue);
      expect(g.canDiscard(1), isFalse);
      g.tap(0);
      expect(g.piles[0], isEmpty);
    });
    test('forty thieves deal and foundation play', () {
      final g = FortyThievesGame(random: Random(3));
      expect(g.tableau.fold<int>(0, (s, t) => s + t.length), 40);
      expect(g.stock.length, 64);
      var guard = 0;
      while (g.stock.isNotEmpty && guard++ < 200) {
        g.draw();
        g.autoMove(-1);
      }
      expect(g.foundations.fold<int>(0, (s, f) => s + f.length) + g.waste.length + g.tableau.fold<int>(0, (s, t) => s + t.length), 104);
    });
  });

  group('Sokoban', () {
    test('generated easy levels are solvable and deterministic', () {
      for (final seed in [1, 2, 3, 4, 5]) {
        final l = SokobanLevel.generate(seed, size: 6, boxCount: 2);
        expect(l.boxes.length, 2);
        expect(solvable(l), isTrue, reason: 'seed $seed');
        expect(SokobanLevel.generate(seed, size: 6, boxCount: 2).boxes, l.boxes);
      }
    });
    test('pushing and undo', () {
      final g = SokobanGame(SokobanLevel.generate(9, size: 6, boxCount: 2));
      var moved = false;
      for (var d = 0; d < 4 && !moved; d++) {
        moved = g.step(d);
      }
      expect(moved, isTrue);
      g.undo();
      expect(g.moves, 0);
    });
  });
}
