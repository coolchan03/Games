import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/ui/features/games/black_box/black_box_engine.dart';
import 'package:puzzle/ui/features/games/black_box/black_box_screen.dart';
import 'package:puzzle/ui/features/games/code_breaker/code_breaker_engine.dart';
import 'package:puzzle/ui/features/games/code_breaker/code_breaker_screen.dart';
import 'package:puzzle/ui/features/games/common/campaign_level_bar.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_screen.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/layered_board.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/engine/mahjong_tile.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/mahjong_screen.dart';
import 'package:puzzle/ui/features/games/mahjong_solitaire/mahjong_tile_art.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_screen.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_engine.dart';
import 'package:puzzle/ui/features/games/same_game/same_game_screen.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_engine.dart';
import 'package:puzzle/ui/features/games/signpost/signpost_screen.dart';
import 'package:puzzle/ui/features/games/sixteen/sixteen_screen.dart';
import 'package:puzzle/ui/features/games/tower_of_hanoi/tower_of_hanoi_screen.dart';
import 'package:puzzle/ui/features/games/twiddle/twiddle_screen.dart';

const _levels = campaignLevelCount;

/// True when the pegs can be reduced to a single peg (depth-first search
/// with a table of dead positions).
bool pegSolvable(PegBoard board) {
  final jumps = <(int, int, int)>[];
  for (var from = 0; from < 49; from++) {
    if (!board.holes[from]) continue;
    final r = from ~/ 7, c = from % 7;
    for (final (dr, dc) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final tr = r + 2 * dr, tc = c + 2 * dc;
      if (tr < 0 || tr > 6 || tc < 0 || tc > 6) continue;
      final over = (r + dr) * 7 + c + dc, to = tr * 7 + tc;
      if (board.holes[over] && board.holes[to]) {
        jumps.add((1 << from, 1 << over, 1 << to));
      }
    }
  }
  final dead = HashSet<int>();
  bool search(int state, int pegs) {
    if (pegs == 1) return true;
    if (dead.contains(state)) return false;
    for (final (f, o, t) in jumps) {
      if (state & f != 0 && state & o != 0 && state & t == 0) {
        if (search(state ^ f ^ o ^ t, pegs - 1)) return true;
      }
    }
    dead.add(state);
    return false;
  }

  var start = 0;
  for (var i = 0; i < 49; i++) {
    if (board.pegs[i]) start |= 1 << i;
  }
  return search(start, board.remaining);
}

/// Plays an Inertia level the way the generator guarantees it can be won:
/// only ever stopping on squares from which the start can be reached again,
/// it slides (breadth-first, avoiding mines) to the nearest move that
/// collects a gem. Returns true if every gem was collected.
bool playInertia(InertiaGame game) {
  (int, List<int>)? slide(int pos, int d) {
    var x = pos % game.w, y = pos ~/ game.w;
    if (game.at(game.grid, x + dirX(d), y + dirY(d)) == Cell.wall) return null;
    final passed = <int>[];
    while (true) {
      x += dirX(d);
      y += dirY(d);
      final i = y * game.w + x;
      final cell = game.grid[i];
      if (cell == Cell.mine) return null;
      passed.add(i);
      if (cell == Cell.stop ||
          game.at(game.grid, x + dirX(d), y + dirY(d)) == Cell.wall) {
        return (i, passed);
      }
    }
  }

  // Squares that can slide back to the start (gems never block a slide).
  final start = game.py * game.w + game.px;
  final cells = game.w * game.h;
  final ends = [
    for (var p = 0; p < cells; p++)
      [for (var d = 0; d < 8; d++) slide(p, d)?.$1].whereType<int>().toList(),
  ];
  final safe = {start};
  for (var changed = true; changed;) {
    changed = false;
    for (var p = 0; p < cells; p++) {
      if (!safe.contains(p) && ends[p].any(safe.contains)) {
        changed = safe.add(p);
      }
    }
  }

  while (!game.won) {
    final from = game.py * game.w + game.px;
    final back = <int, (int, int)>{from: (-1, -1)};
    final queue = Queue.of([from]);
    List<int>? route;
    while (queue.isNotEmpty && route == null) {
      final pos = queue.removeFirst();
      for (var d = 0; d < 8; d++) {
        final step = slide(pos, d);
        if (step == null || !safe.contains(step.$1)) continue;
        final (end, passed) = step;
        if (passed.any((i) => game.grid[i] == Cell.gem)) {
          route = [d];
          for (var p = pos; p != from; p = back[p]!.$1) {
            route.insert(0, back[p]!.$2);
          }
          break;
        }
        if (!back.containsKey(end)) {
          back[end] = (pos, d);
          queue.add(end);
        }
      }
    }
    if (route == null) return false;
    final before = game.gems;
    for (final d in route) {
      if (!game.move(d)) return false;
    }
    if (game.dead || game.gems >= before) return false;
  }
  return true;
}

void main() {
  group('Signpost campaign', () {
    test('20 fixed levels, each with exactly one solution', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final a = SignpostLevels.build(level);
        final b = SignpostLevels.build(level);
        expect(a.solution, b.solution, reason: 'level $level is fixed');
        expect(a.w, SignpostLevels.sizeFor(level));
        expect(a.countSolutions(limit: 2), 1, reason: 'level $level');
        expect(seen.add('${a.arrows}${a.clues}'), isTrue);
      }
      expect(SignpostLevels.sizeFor(1), lessThan(SignpostLevels.sizeFor(20)));
    });
  });

  group('Sixteen and Twiddle campaigns', () {
    test('Sixteen levels are fixed, distinct and start unsolved', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final game = SixteenLevels.build(level);
        expect(game.solved, isFalse);
        expect(game.tiles, SixteenLevels.build(level).tiles);
        expect(seen.add('${game.n}:${game.tiles}'), isTrue);
      }
    });

    test('Twiddle levels are fixed, distinct and start unsolved', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final game = TwiddleLevels.build(level);
        expect(game.solved, isFalse);
        expect(game.tiles, TwiddleLevels.build(level).tiles);
        expect(seen.add('${game.n}/${game.block}:${game.tiles}'), isTrue);
      }
    });

    test('Sixteen shifts undo exactly', () {
      final game = SixteenLevels.build(1);
      final start = List.of(game.tiles);
      game.shiftRow(1, 1);
      game.shiftRow(1, -1);
      game.shiftCol(2, -1);
      game.shiftCol(2, 1);
      expect(game.tiles, start);
    });
  });

  group('Black Box campaign', () {
    test('20 distinct box sizes and ball counts', () {
      expect(BlackBoxLevels.specs.length, _levels);
      expect(BlackBoxLevels.specs.toSet().length, _levels);
      for (var level = 1; level <= _levels; level++) {
        final game = BlackBoxLevels.build(level);
        expect(game.hidden.length, game.balls);
        expect(game.balls, lessThan(game.n * game.n));
      }
    });

    test('exact and laser-equivalent answers are both correct', () {
      final game = BlackBoxLevels.build(5);
      game.guesses.addAll(game.hidden);
      expect(game.correct, isTrue);

      // Four balls in a 2×2 block hide the inner square layout from every
      // laser only if it gives identical results; check the engine agrees
      // with a direct comparison for a wrong guess.
      final wrong = BlackBoxLevels.build(5);
      final cells = List.generate(wrong.n * wrong.n, (i) => i)
          .where((i) => !wrong.hidden.contains(i))
          .take(wrong.balls)
          .toSet();
      wrong.guesses.addAll(cells);
      expect(wrong.correct, wrong.indistinguishable(cells));
    });
  });

  group('Same Game campaign', () {
    test('every level is a fixed board built to be cleared', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final game = SameGameLevels.build(level);
        final (w, h, colours) = SameGameLevels.specs[level - 1];
        expect(game.provablyClearable, isTrue, reason: 'level $level');
        expect(game.grid.length, w * h);
        expect(game.grid.every((c) => c >= 1 && c <= colours), isTrue);
        expect(game.grid, SameGameLevels.build(level).grid);
        expect(seen.add('$w,$h:${game.grid}'), isTrue);
      }
    });
  });

  group('Inertia campaign', () {
    test('every level can be cleared of gems without touching a mine', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final game = InertiaLevels.build(level);
        expect(seen.add('${game.w}:${game.grid}'), isTrue);
        expect(game.totalGems, greaterThan(0));
        expect(playInertia(game), isTrue, reason: 'level $level');
      }
    });
  });

  group('Tower of Hanoi campaign', () {
    int bfs(HanoiGame start) {
      final n = start.discs;
      List<int> pegsOf(HanoiGame g) => [
            for (var d = 1; d <= n; d++) g.pegs.indexWhere((p) => p.contains(d))
          ];
      final goal = List.filled(n, 2).join();
      final first = pegsOf(start).join();
      final dist = {first: 0};
      final queue = Queue.of([pegsOf(start)]);
      while (queue.isNotEmpty) {
        final s = queue.removeFirst();
        final key = s.join();
        if (key == goal) return dist[key]!;
        for (var from = 0; from < 3; from++) {
          final top = s.indexOf(from); // smallest disc on that peg
          if (top < 0) continue;
          for (var to = 0; to < 3; to++) {
            if (to == from) continue;
            final other = s.indexOf(to);
            if (other >= 0 && other < top) continue;
            final next = List.of(s)..[top] = to;
            if (dist.containsKey(next.join())) continue;
            dist[next.join()] = dist[key]! + 1;
            queue.add(next);
          }
        }
      }
      return -1;
    }

    test('levels are distinct and their minimum matches a full search', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final game = HanoiLevels.build(level);
        expect(game.solved, isFalse);
        expect(seen.add('${game.pegs}'), isTrue, reason: 'level $level');
        if (game.discs <= 6) {
          expect(game.optimal, bfs(game), reason: 'level $level');
        }
        final (discs, scrambled) = HanoiLevels.specs[level - 1];
        if (!scrambled) expect(game.optimal, (1 << discs) - 1);
      }
    });

    test('following the hint solves each level in the minimum moves', () {
      for (var level = 1; level <= _levels; level++) {
        final game = HanoiLevels.build(level);
        while (!game.solved) {
          final (from, to) = game.hint()!;
          expect(game.move(from, to), isTrue);
        }
        expect(game.moves, game.optimal, reason: 'level $level');
      }
    });
  });

  group('Peg Solitaire campaign', () {
    test('20 distinct levels, each solvable to a single peg', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final board = PegLevels.build(level);
        expect(seen.add('${board.pegs}'), isTrue, reason: 'level $level');
        expect(pegSolvable(board), isTrue, reason: PegLevels.nameFor(level));
      }
      expect(PegLevels.build(20).remaining, 32);
      expect(PegLevels.build(20).pegs[24], isFalse);
    });
  });

  group('Triangle peg game', () {
    bool solvable(TrianglePegBoard b) {
      if (b.remaining == 1) return true;
      for (var from = 0; from < TrianglePegBoard.holeCount; from++) {
        for (final to in b.targets(from)) {
          b.move(from, to);
          final ok = solvable(b);
          b.undo();
          if (ok) return true;
        }
      }
      return false;
    }

    test('every starting hole can be finished with one peg', () {
      for (var hole = 0; hole < TrianglePegBoard.holeCount; hole++) {
        final board = TrianglePegBoard()..begin(hole);
        expect(board.remaining, 14);
        expect(solvable(board), isTrue, reason: 'start hole $hole');
      }
    });

    test('jumps follow rows and both diagonals only', () {
      final board = TrianglePegBoard()..begin(0);
      // From the top hole empty, only holes 3 and 5 can jump into it.
      final movers = [
        for (var i = 0; i < 15; i++)
          if (board.targets(i).contains(0)) i
      ];
      expect(movers, [3, 5]);
      expect(board.move(3, 0), isTrue);
      expect(board.pegs[1], isFalse);
      expect(board.move(14, 12), isFalse); // 13 is still full, 12 is full
      expect(TrianglePegBoard.rating(1), 'Genius!');
    });

    testWidgets('Triangle mode starts by removing a peg, then jumps',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: PegSolitaireScreen()));
      await tester.tap(find.text('Triangle'));
      await tester.pump();
      expect(find.text('Tap any peg to remove it and start'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('triangle_peg_hole_0')));
      await tester.pump();
      expect(find.text('14 pegs left'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('triangle_peg_hole_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('triangle_peg_hole_0')));
      await tester.pump();
      expect(find.text('13 pegs left'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Code Breaker campaign', () {
    test('20 distinct, playable configurations', () {
      expect(CodeBreakerMode.levels.length, _levels);
      final configs = {
        for (final m in CodeBreakerMode.levels)
          (m.length, m.symbols, m.duplicates, m.maxGuesses)
      };
      expect(configs.length, _levels);
      for (final m in CodeBreakerMode.levels) {
        expect(m.symbols, lessThanOrEqualTo(8)); // colours on screen
        if (!m.duplicates) expect(m.symbols, greaterThanOrEqualTo(m.length));
        final game = CodeBreakerGame(m);
        expect(game.isValid(game.secret), isTrue);
      }
    });
  });

  testWidgets('every Mahjong tile face paints', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (final tile in MahjongTile.values)
          SizedBox(
            width: 30,
            height: 40,
            child: CustomPaint(painter: MahjongFacePainter(tile)),
          ),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });

  group('Mahjong Solitaire campaign', () {
    test('20 fixed deals that clear by their recorded solution', () {
      final seen = <String>{};
      for (var level = 1; level <= _levels; level++) {
        final board = MahjongLevels.build(level);
        final again = MahjongLevels.build(level);
        expect(board.layout.name, MahjongLevels.layoutFor(level).name);
        expect('${board.tiles}', '${again.tiles}');
        expect(seen.add('${board.layout.name}${board.tiles}'), isTrue);
        for (final (a, b) in board.solution) {
          expect(board.remove(a, b), isTrue, reason: 'level $level');
        }
        expect(board.won, isTrue, reason: 'level $level');
      }
    });
  });

  group('Campaign screens', () {
    final screens = <String, Widget Function()>{
      'signpost': () => const SignpostScreen(),
      'sixteen': () => const SixteenScreen(),
      'twiddle': () => const TwiddleScreen(),
      'black_box': () => const BlackBoxScreen(),
      'same_game': () => const SameGameScreen(),
      'inertia': () => const InertiaScreen(),
      'tower_of_hanoi': () => const TowerOfHanoiScreen(),
      'peg_solitaire': () => const PegSolitaireScreen(),
      'code_breaker': () => const CodeBreakerScreen(),
      'mahjong_solitaire': () => const MahjongSolitaireScreen(),
    };

    for (final size in const [Size(360, 740), Size(740, 360)]) {
      for (final entry in screens.entries) {
        testWidgets(
            '${entry.key} shows 20 levels at ${size.width}×${size.height}',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(home: entry.value()));
          await tester.pump();
          expect(find.byKey(ValueKey('${entry.key}_level_selector')),
              findsOneWidget);
          expect(find.text('0 of 20 levels completed'), findsOneWidget);
          await tester.tap(find.byTooltip('Next level'));
          await tester.pump();
          expect(find.textContaining('Level 2'), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Campaign progress storage', () {
    // An in-memory box keeps file I/O out of the widget test's fake clock.
    setUpAll(() async {
      await Hive.openBox(CampaignProgress.boxName, bytes: Uint8List(0));
    });
    tearDownAll(() => Hive.box(CampaignProgress.boxName).close());

    testWidgets('solving records completion and the chosen level persists',
        (tester) async {
      var level = 3;
      var solved = false;
      late StateSetter update;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            update = setState;
            return CampaignLevelBar(
              gameId: 'sixteen',
              level: level,
              solved: solved,
              onLevel: (n) => setState(() {
                level = n;
                solved = false;
              }),
            );
          }),
        ),
      ));
      expect(find.text('0 of 20 levels completed'), findsOneWidget);
      update(() => solved = true);
      await tester.pump();
      expect(find.text('1 of 20 levels completed'), findsOneWidget);
      expect(CampaignProgress.load('sixteen'), {3});

      await tester.tap(find.byKey(const ValueKey('sixteen_next_level')));
      await tester.pump();
      expect(level, 4);
      expect(CampaignLevelBar.initialLevel('sixteen'), 4);
    });
  });
}
