import 'dart:collection';
import 'dart:math' as math;

/// Shared tools for puzzle games that want numbered levels, random levels,
/// proof that a level can be won, and detection of positions the player can no
/// longer win from. Everything here is pure Dart and deterministic for a seed.

// ---------------------------------------------------------------------------
// Search puzzles
// ---------------------------------------------------------------------------

/// A puzzle described as a graph of positions. [key] must be equal for equal
/// positions (use a canonical form to merge symmetric ones).
abstract class SearchPuzzle<S> {
  String key(S state);
  bool isGoal(S state);
  Iterable<S> successors(S state);
}

enum Solvability {
  /// A winning line exists.
  solvable,

  /// The whole reachable space was explored and holds no win: the player is
  /// trapped and can only undo or restart.
  unsolvable,

  /// The search budget ran out; neither proven nor refuted.
  unknown,
}

class SolveResult<S> {
  const SolveResult(this.status, this.path, this.nodes);

  final Solvability status;

  /// Start..goal inclusive (shortest by move count) when [status] is solvable.
  final List<S> path;
  final int nodes;

  /// Number of moves in the shortest solution, or null if none was found.
  int? get moves => status == Solvability.solvable ? path.length - 1 : null;
}

/// Breadth-first search for the shortest solution, bounded by [maxNodes].
SolveResult<S> solvePuzzle<S>(SearchPuzzle<S> puzzle, S start,
    {int maxNodes = 200000}) {
  final startKey = puzzle.key(start);
  if (puzzle.isGoal(start)) return SolveResult(Solvability.solvable, [start], 1);
  final parent = <String, String?>{startKey: null};
  final states = <String, S>{startKey: start};
  final queue = Queue<S>()..add(start);
  while (queue.isNotEmpty) {
    if (parent.length > maxNodes) {
      return SolveResult(Solvability.unknown, const [], parent.length);
    }
    final current = queue.removeFirst();
    final currentKey = puzzle.key(current);
    for (final next in puzzle.successors(current)) {
      final k = puzzle.key(next);
      if (parent.containsKey(k)) continue;
      parent[k] = currentKey;
      states[k] = next;
      if (puzzle.isGoal(next)) {
        final path = <S>[];
        String? at = k;
        while (at != null) {
          path.add(states[at] as S);
          at = parent[at];
        }
        return SolveResult(Solvability.solvable, path.reversed.toList(), parent.length);
      }
      queue.add(next);
    }
  }
  return SolveResult(Solvability.unsolvable, const [], parent.length);
}

/// Answers "can the player still win from here?" and "what is a safe next
/// move?" while a game is in progress. Results are cached by position, and an
/// exhaustive failure marks every position it visited as a dead end, so
/// follow-up checks are instant.
class TrapMonitor<S> {
  TrapMonitor(this.puzzle, {this.maxNodes = 200000});

  final SearchPuzzle<S> puzzle;
  final int maxNodes;
  final Map<String, Solvability> _known = {};

  Solvability analyze(S state) {
    final k = puzzle.key(state);
    final cached = _known[k];
    if (cached != null && cached != Solvability.unknown) return cached;
    final result = solvePuzzle(puzzle, state, maxNodes: maxNodes);
    switch (result.status) {
      case Solvability.solvable:
        for (final s in result.path) {
          _known[puzzle.key(s)] = Solvability.solvable;
        }
      case Solvability.unsolvable:
        _known[k] = Solvability.unsolvable;
      case Solvability.unknown:
        return Solvability.unknown;
    }
    return result.status;
  }

  /// True only when the position is *proven* lost. An inconclusive search
  /// never claims the player is trapped.
  bool isTrapped(S state) => analyze(state) == Solvability.unsolvable;

  /// The position after the best next move, or null when the position is
  /// already won, proven lost or too large to search. A hint is therefore
  /// never offered from a position that cannot be won.
  S? hint(S state) {
    final result = solvePuzzle(puzzle, state, maxNodes: maxNodes);
    if (result.status != Solvability.solvable || result.path.length < 2) return null;
    return result.path[1];
  }
}

// ---------------------------------------------------------------------------
// Seeds and difficulty
// ---------------------------------------------------------------------------

/// Stable 32-bit seed for a numbered level of a game (FNV-1a).
int levelSeed(String gameId, int level) {
  var hash = 0x811C9DC5;
  for (final unit in '$gameId#$level'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

/// 0..1 position of [level] within [levelCount] numbered levels.
double levelDifficulty(int level, int levelCount) =>
    levelCount <= 1 ? 0 : ((level - 1) / (levelCount - 1)).clamp(0.0, 1.0);

/// Fresh seed for "random level" mode.
int randomLevelSeed([math.Random? random]) =>
    (random ?? math.Random()).nextInt(0x7FFFFFFF);

/// Tries successive derived seeds until [verify] accepts a level, so every
/// level a player sees has been proven winnable (and within a move range) by
/// the same solver that later powers trap detection. Returns null only if no
/// attempt passes; callers should fall back to a known-good level.
L? generateVerified<L>({
  required int seed,
  required L Function(math.Random random) make,
  required bool Function(L level) verify,
  int attempts = 40,
}) {
  for (var i = 0; i < attempts; i++) {
    final level = make(math.Random(seed + i * 7919));
    if (verify(level)) return level;
  }
  return null;
}
