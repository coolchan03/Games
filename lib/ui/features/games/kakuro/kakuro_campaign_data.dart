/// Twenty deterministic, offline Kakuro puzzles.
/// Every puzzle has exactly one solution under the displayed sum and
/// no-repeated-digit rules, given its starter digits.
/// Grids store 0 for non-playable cells and 1..9 for white solution cells.
/// Starter digits are flattened row-major grid indices.
class KakuroSeed {
  const KakuroSeed(this.cells, this.starters);
  final List<List<int>> cells;
  final List<int> starters;
  int get size => cells.length;
}

class KakuroCampaignData {
  static const int levelCount = 20;
  static const List<KakuroSeed> levels = <KakuroSeed>[
    // Level 01: 4x4, 3 blanks, 4 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0],
        <int>[ 0,  2,  8,  0],
        <int>[ 0,  6,  2,  0],
        <int>[ 0,  0,  0,  0],
      ],
      <int>[9],
    ),
    // Level 02: 4x4, 4 blanks, 5 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0],
        <int>[ 0,  6,  2,  0],
        <int>[ 0,  7,  3,  0],
        <int>[ 0,  1,  5,  0],
      ],
      <int>[9, 14],
    ),
    // Level 03: 4x4, 5 blanks, 5 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0],
        <int>[ 0,  8,  9,  3],
        <int>[ 0,  9,  3,  5],
        <int>[ 0,  0,  0,  0],
      ],
      <int>[6],
    ),
    // Level 04: 5x5, 5 blanks, 6 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0],
        <int>[ 0,  8,  1,  3,  0],
        <int>[ 0,  5,  4,  6,  0],
        <int>[ 0,  1,  7,  5,  0],
        <int>[ 0,  0,  0,  0,  0],
      ],
      <int>[8, 12, 16, 17],
    ),
    // Level 05: 4x4, 6 blanks, 6 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0],
        <int>[ 0,  4,  9,  5],
        <int>[ 0,  2,  3,  6],
        <int>[ 0,  5,  6,  4],
      ],
      <int>[7, 13, 15],
    ),
    // Level 06: 4x4, 7 blanks, 6 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0],
        <int>[ 0,  5,  7,  1],
        <int>[ 0,  7,  8,  9],
        <int>[ 0,  3,  5,  8],
      ],
      <int>[5, 11],
    ),
    // Level 07: 5x5, 8 blanks, 7 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0],
        <int>[ 0,  4,  6,  2,  0],
        <int>[ 0,  2,  1,  9,  0],
        <int>[ 0,  7,  3,  6,  0],
        <int>[ 0,  5,  9,  4,  0],
      ],
      <int>[8, 16, 17, 21],
    ),
    // Level 08: 5x5, 9 blanks, 7 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0],
        <int>[ 0,  9,  7,  3,  8],
        <int>[ 0,  4,  8,  6,  5],
        <int>[ 0,  1,  2,  5,  4],
        <int>[ 0,  0,  0,  0,  0],
      ],
      <int>[8, 12, 14],
    ),
    // Level 09: 5x5, 10 blanks, 8 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0],
        <int>[ 0,  4,  7,  8,  5],
        <int>[ 0,  8,  3,  6,  2],
        <int>[ 0,  5,  2,  1,  7],
        <int>[ 0,  9,  8,  2,  3],
      ],
      <int>[8, 9, 11, 13, 17, 21],
    ),
    // Level 10: 5x5, 10 blanks, 8 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0],
        <int>[ 0,  2,  1,  8,  3],
        <int>[ 0,  5,  8,  7,  2],
        <int>[ 0,  3,  2,  5,  7],
        <int>[ 0,  7,  9,  1,  4],
      ],
      <int>[6, 11, 12, 21, 23, 24],
    ),
    // Level 11: 6x6, 10 blanks, 8 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0],
        <int>[ 0,  8,  5,  1,  6,  0],
        <int>[ 0,  7,  9,  2,  1,  0],
        <int>[ 0,  2,  3,  5,  7,  0],
        <int>[ 0,  6,  4,  9,  8,  0],
        <int>[ 0,  0,  0,  0,  0,  0],
      ],
      <int>[7, 15, 16, 21, 22, 26],
    ),
    // Level 12: 7x7, 12 blanks, 16 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  9,  6,  0,  2,  7,  0],
        <int>[ 0,  6,  4,  0,  8,  1,  0],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  1,  8,  0,  3,  1,  0],
        <int>[ 0,  3,  2,  0,  1,  8,  0],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
      ],
      <int>[11, 16, 37, 40],
    ),
    // Level 13: 7x7, 13 blanks, 16 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  5,  7,  0,  1,  5,  0],
        <int>[ 0,  4,  6,  0,  8,  7,  0],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  7,  3,  0,  6,  9,  0],
        <int>[ 0,  4,  9,  0,  1,  8,  0],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
      ],
      <int>[9, 19, 30],
    ),
    // Level 14: 6x6, 14 blanks, 9 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0],
        <int>[ 0,  1,  2,  7,  5,  9],
        <int>[ 0,  8,  1,  9,  6,  3],
        <int>[ 0,  6,  9,  2,  3,  4],
        <int>[ 0,  9,  8,  3,  1,  6],
        <int>[ 0,  0,  0,  0,  0,  0],
      ],
      <int>[10, 14, 17, 21, 26, 27],
    ),
    // Level 15: 6x6, 14 blanks, 9 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0],
        <int>[ 0,  6,  8,  9,  4,  0],
        <int>[ 0,  1,  9,  2,  6,  0],
        <int>[ 0,  3,  1,  6,  2,  0],
        <int>[ 0,  2,  7,  4,  5,  0],
        <int>[ 0,  5,  4,  3,  1,  0],
      ],
      <int>[7, 21, 27, 28, 32, 34],
    ),
    // Level 16: 7x7, 14 blanks, 18 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  1,  5,  0,  6,  7,  0],
        <int>[ 0,  4,  6,  0,  5,  3,  0],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  4,  7,  0,  9,  4,  0],
        <int>[ 0,  2,  3,  0,  3,  2,  0],
        <int>[ 0,  7,  4,  0,  1,  7,  0],
      ],
      <int>[11, 15, 29, 37, 39, 47],
    ),
    // Level 17: 7x7, 16 blanks, 18 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  5,  9,  0,  9,  7,  2],
        <int>[ 0,  3,  7,  0,  3,  6,  5],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  9,  4,  0,  8,  4,  6],
        <int>[ 0,  5,  3,  0,  5,  8,  9],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
      ],
      <int>[11, 19, 36, 40],
    ),
    // Level 18: 6x6, 16 blanks, 10 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0],
        <int>[ 0,  7,  9,  5,  6,  2],
        <int>[ 0,  3,  2,  1,  7,  5],
        <int>[ 0,  5,  4,  6,  3,  9],
        <int>[ 0,  9,  1,  3,  2,  8],
        <int>[ 0,  1,  8,  4,  9,  7],
      ],
      <int>[7, 8, 9, 10, 14, 22, 26, 29, 33],
    ),
    // Level 19: 6x6, 17 blanks, 10 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0],
        <int>[ 0,  7,  2,  6,  4,  3],
        <int>[ 0,  1,  3,  5,  2,  4],
        <int>[ 0,  2,  6,  3,  9,  8],
        <int>[ 0,  9,  1,  7,  6,  5],
        <int>[ 0,  5,  8,  4,  1,  6],
      ],
      <int>[7, 9, 13, 16, 20, 25, 28, 29],
    ),
    // Level 20: 7x7, 17 blanks, 20 clue runs.
    KakuroSeed(
      <List<int>>[
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  3,  8,  0,  1,  9,  8],
        <int>[ 0,  7,  3,  0,  6,  1,  4],
        <int>[ 0,  0,  0,  0,  0,  0,  0],
        <int>[ 0,  4,  2,  0,  3,  2,  6],
        <int>[ 0,  2,  9,  0,  2,  8,  9],
        <int>[ 0,  8,  7,  0,  9,  4,  1],
      ],
      <int>[16, 19, 20, 30, 32, 34, 46, 48],
    ),
  ];
  static KakuroSeed seed(int number) {
    RangeError.checkValueInInterval(number, 1, levelCount, 'number');
    return levels[number - 1];
  }
}
