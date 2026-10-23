/// Twenty fixed offline Akari puzzles with solver-certified unique solutions.
///
/// Cell values: -2 means white, -1 means plain wall, 0..4 means numbered wall.
/// Solutions are flattened bulb indices (row * size + column) used for tests.
/// Do not show solutions in the game UI.
class AkariCampaignLevel {
  const AkariCampaignLevel(this.grid, this.solution);

  final List<List<int>> grid;
  final List<int> solution;
  int get size => grid.length;
}

class AkariCampaignData {
  static const int levelCount = 20;

  static const List<AkariCampaignLevel> levels = [
    // Level 01: 5x5, 10 number clues, 4 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2, -2, -2, -2],
        [ 0,  1, -2, -2,  1],
        [-2, -2,  1, -2, -2],
        [ 0,  1,  0,  0, -2],
        [-1,  0,  0, -2, -2],
      ],
      [2, 8, 11, 24],
    ),
    // Level 02: 5x5, 5 number clues, 6 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2, -2,  2, -2],
        [-2,  0,  2, -2,  2],
        [-2, -2, -2, -2,  1],
        [-2, -2, -2, -2, -2],
        [-2, -2, -2, -2, -2],
      ],
      [0, 4, 8, 12, 19, 21],
    ),
    // Level 03: 5x5, 9 number clues, 6 bulbs.
    AkariCampaignLevel(
      [
        [-2,  2, -2,  2, -2],
        [ 1, -2, -2, -2, -2],
        [-2,  0,  0, -2, -2],
        [-2,  1,  0,  1, -2],
        [ 1, -2, -2, -2, -2],
      ],
      [0, 2, 8, 14, 15, 23],
    ),
    // Level 04: 5x5, 6 number clues, 5 bulbs.
    AkariCampaignLevel(
      [
        [ 0, -2, -2, -2, -2],
        [ 0, -2, -2, -2, -2],
        [-2, -2, -2, -2,  3],
        [ 1, -2, -2, -2, -2],
        [-2,  1, -2, -2,  1],
      ],
      [2, 9, 13, 19, 20],
    ),
    // Level 05: 5x5, 6 number clues, 5 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2, -2, -2,  0],
        [-2, -2, -1,  0, -1],
        [-2,  2, -2, -2, -2],
        [ 1,  0, -2, -2, -2],
        [-2, -2, -2, -2,  2],
      ],
      [1, 10, 12, 19, 23],
    ),
    // Level 06: 5x5, 5 number clues, 5 bulbs.
    AkariCampaignLevel(
      [
        [-2,  0, -2, -2,  1],
        [-2, -2,  1, -2,  0],
        [-2,  2, -2, -2, -2],
        [-1, -2, -2, -2, -2],
        [-1, -2, -2, -2, -2],
      ],
      [3, 5, 12, 16, 24],
    ),
    // Level 07: 5x5, 7 number clues, 6 bulbs.
    AkariCampaignLevel(
      [
        [ 1, -2,  3, -2, -2],
        [ 0, -2, -2, -2,  0],
        [ 0, -1, -1, -2,  0],
        [-2, -2, -2, -2, -2],
        [-2, -2, -2,  2, -2],
      ],
      [1, 3, 7, 16, 22, 24],
    ),
    // Level 08: 5x5, 8 number clues, 8 bulbs.
    AkariCampaignLevel(
      [
        [-2,  0,  0, -2, -2],
        [-2, -1, -1, -2, -2],
        [-2,  2, -2,  3, -2],
        [ 2, -2,  4, -2, -2],
        [-2,  3, -2,  2, -2],
      ],
      [4, 5, 8, 12, 16, 18, 20, 22],
    ),
    // Level 09: 5x5, 5 number clues, 5 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2,  1, -1, -2],
        [-1, -2, -2, -2, -2],
        [-2, -2, -1, -2,  2],
        [-2, -2, -2,  2,  0],
        [-2, -2, -2, -2,  0],
      ],
      [1, 9, 13, 17, 20],
    ),
    // Level 10: 6x6, 6 number clues, 9 bulbs.
    AkariCampaignLevel(
      [
        [-1, -2, -2, -2, -1,  1],
        [-2,  2, -2, -2, -2, -2],
        [ 2, -2, -2,  0, -1, -2],
        [-2,  3, -2, -2, -2, -2],
        [-2, -2,  3, -2, -2, -2],
        [-2, -2, -2, -1, -2, -2],
      ],
      [3, 6, 11, 13, 20, 25, 27, 30, 34],
    ),
    // Level 11: 6x6, 7 number clues, 9 bulbs.
    AkariCampaignLevel(
      [
        [-2,  2, -2, -2, -2, -2],
        [-2, -2, -2,  2, -2, -2],
        [-2, -2, -2, -2,  3, -2],
        [-2, -1, -2,  1, -2, -1],
        [-2, -2, -2,  1, -2, -1],
        [ 0, -2, -2,  0, -1, -2],
      ],
      [2, 7, 10, 15, 17, 18, 25, 28, 35],
    ),
    // Level 12: 6x6, 7 number clues, 8 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2,  1, -2, -2, -2],
        [ 2, -2, -2,  1, -2, -2],
        [-2, -1,  2, -2, -2, -2],
        [-1, -2, -2,  2, -2,  0],
        [-1, -1, -2, -2, -2, -2],
        [ 0, -2, -2, -2, -2, -2],
      ],
      [0, 5, 8, 12, 16, 20, 27, 35],
    ),
    // Level 13: 6x6, 10 number clues, 8 bulbs.
    AkariCampaignLevel(
      [
        [-2,  1, -2,  2, -2, -1],
        [ 1, -2, -2, -2,  2,  0],
        [ 0,  1, -2, -2, -2, -1],
        [-1, -2, -2, -2, -2, -2],
        [-2, -2,  2, -2,  2, -2],
        [-2, -2, -2, -1, -1,  1],
      ],
      [0, 4, 9, 14, 22, 25, 29, 32],
    ),
    // Level 14: 6x6, 6 number clues, 6 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2,  1, -1, -2,  0],
        [ 0, -2, -2, -1, -2, -2],
        [-1, -2, -2, -2, -2, -2],
        [-2, -2,  1, -2,  1, -2],
        [-2, -2, -2, -2, -2, -2],
        [-1, -2,  1, -2, -2, -1],
      ],
      [1, 10, 14, 23, 24, 33],
    ),
    // Level 15: 6x6, 7 number clues, 7 bulbs.
    AkariCampaignLevel(
      [
        [ 0, -1,  1, -2, -2,  1],
        [ 0,  1, -2, -2, -2, -2],
        [-2, -2, -1, -2, -2, -2],
        [-2, -2, -2, -2, -2,  0],
        [-2, -2, -2, -2, -1, -1],
        [ 2, -2, -2, -2, -1, -2],
      ],
      [4, 8, 15, 20, 24, 31, 35],
    ),
    // Level 16: 6x6, 6 number clues, 7 bulbs.
    AkariCampaignLevel(
      [
        [-2, -1, -2, -2,  0, -2],
        [-2,  1, -2, -2, -2, -2],
        [-1, -2, -2, -2, -2, -1],
        [-1, -2,  0, -2, -2, -2],
        [ 0, -2, -2, -2, -2, -2],
        [-2, -2, -1,  0, -2,  0],
      ],
      [2, 6, 11, 15, 23, 28, 31],
    ),
    // Level 17: 6x6, 6 number clues, 8 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2, -2, -2, -2, -2],
        [-2,  0, -2,  2, -2, -2],
        [ 0, -2, -2, -2,  3, -2],
        [-2, -2, -2, -2, -2,  2],
        [ 1, -2, -1, -2, -2, -2],
        [-1, -2, -1, -1, -2, -2],
      ],
      [0, 10, 15, 17, 20, 25, 29, 34],
    ),
    // Level 18: 7x7, 7 number clues, 8 bulbs.
    AkariCampaignLevel(
      [
        [ 1, -2, -2, -2, -2, -1, -2],
        [-2, -2, -1, -2, -1, -2, -2],
        [-2, -2, -1, -2,  0, -2,  0],
        [-2, -2, -2, -2,  2, -2, -2],
        [-2, -1,  1, -2, -2, -2,  1],
        [-2, -2, -2, -2, -2, -2, -2],
        [-2, -2,  0, -2, -2, -2, -2],
      ],
      [1, 6, 10, 23, 26, 32, 41, 42],
    ),
    // Level 19: 7x7, 7 number clues, 9 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2, -2, -2, -1, -2, -2],
        [-2, -2, -2, -2, -1, -2, -2],
        [-2,  1, -2, -2, -2, -2,  2],
        [ 0, -1, -1, -2, -2,  2, -2],
        [-2,  1,  0, -2,  0, -2, -1],
        [-2, -2, -1, -2, -2, -2, -1],
        [-2, -2, -2, -2, -2, -2, -1],
      ],
      [0, 6, 8, 19, 24, 27, 36, 40, 42],
    ),
    // Level 20: 7x7, 8 number clues, 6 bulbs.
    AkariCampaignLevel(
      [
        [-2, -2,  2, -2, -2, -1, -1],
        [-2, -2,  0, -2, -1,  0, -1],
        [-2, -2, -1, -2,  0,  0, -2],
        [-2, -2, -2, -2, -2, -2, -2],
        [-2, -2,  0, -2, -2, -2, -2],
        [-1,  1, -1, -2, -2,  0, -2],
        [-2, -2, -2, -2, -1, -2, -2],
      ],
      [1, 3, 21, 32, 43, 48],
    ),
  ];

  static AkariCampaignLevel level(int number) {
    RangeError.checkValueInInterval(number, 1, levelCount, 'number');
    return levels[number - 1];
  }

  /// Fresh mutable copy; source data must not change after a level is played.
  static List<List<int>> board(int number) => [
    for (final row in level(number).grid) List<int>.of(row),
  ];
}
