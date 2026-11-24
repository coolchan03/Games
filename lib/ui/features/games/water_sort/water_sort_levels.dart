import 'dart:math';

import '../common/level_kit.dart';

/// Tubes of colour ids (bottom to top). Every level is produced by scrambling
/// the solved state with *reverse pours*, so it is winnable by construction;
/// the solver in [WaterSortPuzzle] then powers hints and trap detection.
typedef Tubes = List<List<int>>;

class WaterSortLevel {
  const WaterSortLevel({
    required this.tubes,
    required this.colors,
    required this.par,
    required this.seed,
  });

  final Tubes tubes;
  final int colors;

  /// Moves a good player needs (shortest known, or the scramble length).
  final int par;
  final int seed;
}

class WaterSortLevels {
  static const int count = 30;
  static const int capacity = 4;
  static const int emptyTubes = 2;
  static const int maxColors = 8;

  /// Colours grow from 3 to 8 across the 30 levels.
  static int colorsFor(int level) =>
      3 + (levelDifficulty(level, count) * (maxColors - 3)).round();

  static String describe(int level) => '${colorsFor(level)} colours';

  static WaterSortLevel build(int level) =>
      _generate(levelSeed('water_sort', level), levelDifficulty(level, count));

  /// A new random level at the difficulty of [level].
  static WaterSortLevel random(int level, [Random? random]) =>
      _generate(randomLevelSeed(random), levelDifficulty(level, count));

  static WaterSortLevel fromSeed(int seed, int level) =>
      _generate(seed, levelDifficulty(level, count));

  static WaterSortLevel _generate(int seed, double difficulty) {
    final colors = 3 + (difficulty * (maxColors - 3)).round();
    final steps = 12 + (difficulty * 60).round() + colors * 2;
    for (var attempt = 0; attempt < 20; attempt++) {
      final random = Random(seed + attempt * 104729);
      final tubes = scramble(colors, steps, random);
      if (!isSolved(tubes) && _mixedTubes(tubes) >= min(colors, 3)) {
        return WaterSortLevel(
          tubes: tubes,
          colors: colors,
          par: _par(tubes, steps, colors),
          seed: seed,
        );
      }
    }
    // Practically unreachable; a trivially winnable fallback.
    final tubes = scramble(colors, steps, Random(seed));
    return WaterSortLevel(tubes: tubes, colors: colors, par: steps, seed: seed);
  }

  static int _mixedTubes(Tubes tubes) =>
      tubes.where((t) => t.toSet().length > 1).length;

  static int _par(Tubes tubes, int steps, int colors) {
    if (colors > 5) return steps;
    final r = solvePuzzle(WaterSortPuzzle(), tubes, maxNodes: 30000);
    return r.moves != null ? min(r.moves!, steps) : steps;
  }

  /// Solved tubes, then [steps] random reverse pours (see class docs).
  static Tubes scramble(int colors, int steps, Random random) {
    final tubes = <List<int>>[
      for (var c = 0; c < colors; c++) List.filled(capacity, c, growable: true),
      for (var i = 0; i < emptyTubes; i++) <int>[],
    ];
    var done = 0, guard = 0;
    while (done < steps && guard++ < steps * 50) {
      final from = random.nextInt(tubes.length);
      final src = tubes[from];
      if (src.isEmpty) continue;
      final color = src.last;
      var run = 0;
      while (run < src.length && src[src.length - 1 - run] == color) {
        run++;
      }
      // Leave the colour on top of the source (or empty it entirely) so the
      // forward pour back onto it is legal.
      final maxTake = src.length == run ? run : run - 1;
      if (maxTake < 1) continue;
      final take = 1 + random.nextInt(maxTake);
      final to = random.nextInt(tubes.length);
      if (to == from) continue;
      final dst = tubes[to];
      if (dst.length + take > capacity) continue;
      if (dst.isNotEmpty && dst.last == color) continue;
      dst.addAll(src.sublist(src.length - take));
      src.removeRange(src.length - take, src.length);
      done++;
    }
    return tubes;
  }

  static bool isSolved(Tubes tubes) => tubes.every(
      (t) => t.isEmpty || (t.length == capacity && t.every((c) => c == t.first)));

  static bool canPour(List<int> from, List<int> to) {
    if (from.isEmpty || to.length >= capacity) return false;
    return to.isEmpty || from.last == to.last;
  }

  /// Pours the whole top run of [from] into [to] as far as there is room.
  static void pour(List<int> from, List<int> to) {
    final color = from.last;
    while (from.isNotEmpty && from.last == color && to.length < capacity) {
      to.add(from.removeLast());
    }
  }

  static Tubes copy(Tubes tubes) => [for (final t in tubes) [...t]];

  // -- Saving ---------------------------------------------------------------

  /// `[moves, len0, ...tube0, len1, ...tube1, ...]`
  static List<int> encode(Tubes tubes, int moves) => [
        moves,
        for (final t in tubes) ...[t.length, ...t],
      ];

  /// Restores a save, or null unless it holds exactly the colours of [level].
  static (Tubes, int)? decode(List<int> data, WaterSortLevel level) {
    if (data.isEmpty) return null;
    final tubes = <List<int>>[];
    var i = 1;
    while (i < data.length) {
      final len = data[i++];
      if (len < 0 || len > capacity || i + len > data.length) return null;
      tubes.add(data.sublist(i, i + len));
      i += len;
    }
    List<int> sorted(Tubes t) => [for (final x in t) ...x]..sort();
    final a = sorted(tubes), b = sorted(level.tubes);
    if (tubes.length != level.tubes.length || a.length != b.length) return null;
    for (var k = 0; k < a.length; k++) {
      if (a[k] != b[k]) return null;
    }
    return (tubes, data[0] < 0 ? 0 : data[0]);
  }
}

/// Position graph for the solver. Tubes that differ only by order are merged.
class WaterSortPuzzle extends SearchPuzzle<Tubes> {
  @override
  String key(Tubes s) => ([for (final t in s) t.join(',')]..sort()).join('|');

  @override
  bool isGoal(Tubes s) => WaterSortLevels.isSolved(s);

  @override
  Iterable<Tubes> successors(Tubes s) sync* {
    for (var i = 0; i < s.length; i++) {
      final from = s[i];
      if (from.isEmpty) continue;
      final mono = from.every((c) => c == from.first);
      // A finished tube, or shuffling a single colour into an empty tube,
      // never helps.
      if (mono && from.length == WaterSortLevels.capacity) continue;
      for (var j = 0; j < s.length; j++) {
        if (i == j || !WaterSortLevels.canPour(from, s[j])) continue;
        if (mono && s[j].isEmpty) continue;
        final next = WaterSortLevels.copy(s);
        WaterSortLevels.pour(next[i], next[j]);
        yield next;
      }
    }
  }
}
