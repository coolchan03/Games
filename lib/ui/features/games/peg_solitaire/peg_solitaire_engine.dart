/// English (33-hole cross) and European (37-hole) peg solitaire.
class PegBoard {
  PegBoard({this.european = false}) {
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        final arm = (r >= 2 && r <= 4) || (c >= 2 && c <= 4);
        final corner = european && (r == 1 || r == 5) && (c == 1 || c == 5);
        holes[r * 7 + c] = arm || corner;
      }
    }
    for (var i = 0; i < 49; i++) {
      pegs[i] = holes[i];
    }
    pegs[24] = false;
  }

  /// English board with pegs only where [rows] (7 strings of 7 characters)
  /// has an 'o'.
  PegBoard.pattern(List<String> rows) : european = false {
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        holes[r * 7 + c] = (r >= 2 && r <= 4) || (c >= 2 && c <= 4);
        pegs[r * 7 + c] = holes[r * 7 + c] && rows[r][c] == 'o';
      }
    }
  }

  final bool european;
  final holes = List.filled(49, false);
  final pegs = List.filled(49, false);
  final List<(int, int, int)> history = [];

  int get remaining => pegs.where((p) => p).length;

  /// Jump over [over] into [to]; null if illegal.
  (int, int)? _jump(int from, int to) {
    final fr = from ~/ 7, fc = from % 7, tr = to ~/ 7, tc = to % 7;
    if (!((fr == tr && (fc - tc).abs() == 2) ||
        (fc == tc && (fr - tr).abs() == 2))) return null;
    final over = ((fr + tr) ~/ 2) * 7 + (fc + tc) ~/ 2;
    if (!pegs[from] || !pegs[over] || !holes[to] || pegs[to]) return null;
    return (over, to);
  }

  List<int> targets(int from) => [
        for (final d in const [-14, 14, -2, 2])
          if (from + d >= 0 && from + d < 49 && _jump(from, from + d) != null)
            from + d
      ];

  bool move(int from, int to) {
    final j = _jump(from, to);
    if (j == null) return false;
    pegs[from] = false;
    pegs[j.$1] = false;
    pegs[to] = true;
    history.add((from, j.$1, to));
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final (from, over, to) = history.removeLast();
    pegs[from] = true;
    pegs[over] = true;
    pegs[to] = false;
  }

  bool get stuck => ![
        for (var i = 0; i < 49; i++)
          if (pegs[i]) i
      ].any((i) => targets(i).isNotEmpty);
  bool get perfect => remaining == 1 && pegs[24];
}

/// The 20 numbered Peg Solitaire levels on the English board: classic
/// patterns from 6 to 28 pegs, then the full board started from each of its
/// seven different empty holes (up to symmetry), finishing with the centre.
/// Every level has been checked to be solvable down to a single peg.
class PegLevels {
  static const specs = <(String, List<String>)>[
    (
      'Cross',
      [
        '  ...  ',
        '  .o.  ',
        '..ooo..',
        '...o...',
        '...o...',
        '  ...  ',
        '  ...  '
      ]
    ),
    (
      'Chevron',
      [
        '  ...  ',
        '  ...  ',
        '...o...',
        '..ooo..',
        '.oo.oo.',
        '  ...  ',
        '  ...  '
      ]
    ),
    (
      'Plus',
      [
        '  ...  ',
        '  .o.  ',
        '...o...',
        '.ooooo.',
        '...o...',
        '  .o.  ',
        '  ...  '
      ]
    ),
    (
      'Pentagon',
      [
        '  ...  ',
        '  ...  ',
        '..ooo..',
        '..ooo..',
        '..ooo..',
        '  .o.  ',
        '  ...  '
      ]
    ),
    (
      'Fireplace',
      [
        '  ooo  ',
        '  ooo  ',
        '..ooo..',
        '..o.o..',
        '.......',
        '  ...  ',
        '  ...  '
      ]
    ),
    (
      'Arrow',
      [
        '  .o.  ',
        '  ooo  ',
        '.ooooo.',
        '...o...',
        '...o...',
        '  .o.  ',
        '  .o.  '
      ]
    ),
    (
      'Lantern',
      [
        '  .o.  ',
        '  ooo  ',
        '..ooo..',
        '..ooo..',
        '..ooo..',
        '  .o.  ',
        '  ...  '
      ]
    ),
    (
      'Pyramid',
      [
        '  ...  ',
        '  .o.  ',
        '..ooo..',
        '.ooooo.',
        'ooooooo',
        '  ...  ',
        '  ...  '
      ]
    ),
    (
      'Up arrow',
      [
        '  .o.  ',
        '  ooo  ',
        '.ooooo.',
        '...o...',
        '...o...',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Tower',
      [
        '  ooo  ',
        '  ooo  ',
        '..ooo..',
        '..o.o..',
        '..ooo..',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Fire tower',
      [
        '  ooo  ',
        '  ooo  ',
        'ooooooo',
        'ooo.ooo',
        '...o...',
        '  ...  ',
        '  ...  '
      ]
    ),
    (
      'Diamond',
      [
        '  .o.  ',
        '  ooo  ',
        '.ooooo.',
        'ooo.ooo',
        '.ooooo.',
        '  ooo  ',
        '  .o.  '
      ]
    ),
    (
      'Big diamond',
      [
        '  ooo  ',
        '  ooo  ',
        '.ooooo.',
        'ooo.ooo',
        '.ooooo.',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Corner hole',
      [
        '  .oo  ',
        '  ooo  ',
        'ooooooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Top hole',
      [
        '  o.o  ',
        '  ooo  ',
        'ooooooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Inner corner hole',
      [
        '  ooo  ',
        '  .oo  ',
        'ooooooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Inner hole',
      [
        '  ooo  ',
        '  o.o  ',
        'ooooooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Elbow hole',
      [
        '  ooo  ',
        '  ooo  ',
        'oo.oooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Near-centre hole',
      [
        '  ooo  ',
        '  ooo  ',
        'ooo.ooo',
        'ooooooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
    (
      'Classic',
      [
        '  ooo  ',
        '  ooo  ',
        'ooooooo',
        'ooo.ooo',
        'ooooooo',
        '  ooo  ',
        '  ooo  '
      ]
    ),
  ];

  static String nameFor(int level) => specs[level - 1].$1;

  static PegBoard build(int level) => PegBoard.pattern(specs[level - 1].$2);
}

/// The 15-hole triangle peg game often found on restaurant tables. Holes
/// are numbered row by row from the top: row r (0–4) holds r + 1 holes.
/// Pegs jump along the rows and both diagonals.
class TrianglePegBoard {
  TrianglePegBoard() : pegs = List.filled(holeCount, true);

  static const rows = 5;
  static const holeCount = 15;

  final List<bool> pegs;
  final List<(int, int, int)> history = [];

  /// The hole the player emptied to begin, or null before the game starts.
  int? startHole;

  bool get started => startHole != null;
  int get remaining => pegs.where((p) => p).length;

  static int index(int r, int c) => r * (r + 1) ~/ 2 + c;
  static (int, int) position(int i) {
    var r = 0;
    while (index(r + 1, 0) <= i) {
      r++;
    }
    return (r, i - index(r, 0));
  }

  static bool _valid(int r, int c) => r >= 0 && r < rows && c >= 0 && c <= r;

  static const _directions = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
    (1, 1),
    (-1, -1)
  ];

  /// Empties [hole] to start the game.
  void begin(int hole) {
    if (started) return;
    pegs[hole] = false;
    startHole = hole;
  }

  int? _over(int from, int to) {
    final (fr, fc) = position(from);
    final (tr, tc) = position(to);
    for (final (dr, dc) in _directions) {
      if (fr + 2 * dr == tr && fc + 2 * dc == tc) {
        return index(fr + dr, fc + dc);
      }
    }
    return null;
  }

  List<int> targets(int from) {
    if (!started || !pegs[from]) return const [];
    final (r, c) = position(from);
    return [
      for (final (dr, dc) in _directions)
        if (_valid(r + 2 * dr, c + 2 * dc) &&
            pegs[index(r + dr, c + dc)] &&
            !pegs[index(r + 2 * dr, c + 2 * dc)])
          index(r + 2 * dr, c + 2 * dc),
    ];
  }

  bool move(int from, int to) {
    if (!targets(from).contains(to)) return false;
    final over = _over(from, to)!;
    pegs[from] = false;
    pegs[over] = false;
    pegs[to] = true;
    history.add((from, over, to));
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final (from, over, to) = history.removeLast();
    pegs[from] = true;
    pegs[over] = true;
    pegs[to] = false;
  }

  bool get stuck =>
      started &&
      ![for (var i = 0; i < holeCount; i++) i]
          .any((i) => targets(i).isNotEmpty);

  /// The traditional verdict printed on the board for the pegs left.
  static String rating(int left) => switch (left) {
        1 => 'Genius!',
        2 => 'Pretty smart',
        3 => 'Just average',
        _ => 'Keep practising',
      };
}
