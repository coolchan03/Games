import 'dart:math';

import '../lights_out/lights_out_levels.dart';
import '../mahjong_solitaire/engine/layered_board.dart';
import '../sokoban/sokoban_analysis.dart';
import '../sokoban/sokoban_engine.dart';
import '../water_sort/water_sort_levels.dart';
import 'level_kit.dart';

/// Result of checking one level.
enum AuditStatus {
  /// A winning line was found (or the level was replayed from its dealing
  /// order), so the level is definitely completable.
  proven,

  /// Generated winnable-by-construction but the budget was too small to
  /// confirm it independently.
  unverified,

  /// Proven impossible: a bug in the generator.
  impossible,
}

class AuditEntry {
  const AuditEntry(this.game, this.level, this.status, [this.detail = '']);
  final String game;
  final String level;
  final AuditStatus status;
  final String detail;
}

AuditStatus _fromSolve(Solvability s) => switch (s) {
      Solvability.solvable => AuditStatus.proven,
      Solvability.unknown => AuditStatus.unverified,
      Solvability.unsolvable => AuditStatus.impossible,
    };

/// One audit per game that has generated or numbered levels. To cover a new
/// game, add a function here that builds each level (numbered and random) and
/// checks it with the game's solver. Run with
/// `flutter test test/games/level_audit_test.dart`.
final Map<String, List<AuditEntry> Function(int randomSeeds)> levelAudits = {
  'water_sort': (randomSeeds) {
    final out = <AuditEntry>[];
    void check(String name, WaterSortLevel level) {
      final r = solveDepthFirst(WaterSortPuzzle(), level.tubes, maxNodes: 60000);
      out.add(AuditEntry('water_sort', name, _fromSolve(r.status)));
    }

    for (var l = 1; l <= WaterSortLevels.count; l++) {
      check('level $l', WaterSortLevels.build(l));
    }
    final random = Random(11);
    for (var i = 0; i < randomSeeds; i++) {
      check('random #$i', WaterSortLevels.random(1 + random.nextInt(WaterSortLevels.count), random));
    }
    return out;
  },
  'lights_out': (randomSeeds) {
    final out = <AuditEntry>[];
    void check(String name, LightsOutLevel level) {
      final solution = LightsOutSolver.solve(level.size, level.lights);
      out.add(AuditEntry('lights_out', name,
          solution == null ? AuditStatus.impossible : AuditStatus.proven));
    }

    for (var l = 1; l <= LightsOutLevels.count; l++) {
      check('level $l', LightsOutLevels.build(l));
    }
    final random = Random(12);
    for (var i = 0; i < randomSeeds; i++) {
      check('random #$i', LightsOutLevels.random(1 + random.nextInt(LightsOutLevels.count), random));
    }
    return out;
  },
  'mahjong_solitaire': (randomSeeds) {
    final out = <AuditEntry>[];
    // A deal is proven by replaying the removal order it was dealt from.
    AuditEntry replay(String name, LayeredBoard board) {
      var ok = true;
      for (final (a, b) in List.of(board.solution)) {
        if (!board.remove(a, b)) {
          ok = false;
          break;
        }
      }
      ok = ok && board.won;
      return AuditEntry('mahjong_solitaire', name, ok ? AuditStatus.proven : AuditStatus.impossible);
    }

    for (var l = 1; l <= MahjongLevels.specs.length; l++) {
      out.add(replay('level $l', MahjongLevels.build(l)));
    }
    final layouts = Layout.all();
    for (var i = 0; i < randomSeeds ~/ 4; i++) {
      final layout = layouts[i % layouts.length];
      out.add(replay('random ${layout.name} #$i', LayeredBoard(layout, random: Random(500 + i))));
    }
    return out;
  },
  'sokoban': (randomSeeds) {
    final out = <AuditEntry>[];
    final configs = [(6, 2), (7, 3), (8, 4)];
    for (var d = 0; d < configs.length; d++) {
      for (var l = 1; l <= 20; l++) {
        final (size, boxes) = configs[d];
        final level = SokobanLevel.generate(l * 31 + d, size: size, boxCount: boxes);
        final r = solvePuzzle(SokobanPuzzle(level),
            (boxes: Set<int>.of(level.boxes), player: level.player),
            maxNodes: 40000);
        final trappedAtStart = SokobanAnalysis(level).trapped(level.boxes);
        out.add(AuditEntry(
            'sokoban',
            '${['easy', 'medium', 'hard'][d]} $l',
            trappedAtStart ? AuditStatus.impossible : _fromSolve(r.status),
            trappedAtStart ? 'starts in a deadlock' : ''));
      }
    }
    return out;
  },
};
