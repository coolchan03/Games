import 'dart:math';

class WordSearchWord {
  final String word;
  final List<Point<int>> positions;
  bool isFound;

  WordSearchWord({
    required this.word,
    required this.positions,
    this.isFound = false,
  });
}

class WordSearchBoard {
  final int size;
  final List<List<String>> grid;
  final List<WordSearchWord> words;

  WordSearchBoard({
    required this.size,
    required this.grid,
    required this.words,
  });
}

class WordSearchEngine {
  static const int boardSize = 10;
  static const int campaignLevelCount = 20;

  static const campaignThemes = <String>[
    'Detective Files', 'Space', 'Ocean', 'Garden', 'Ancient World',
    'Music', 'Forest', 'Science', 'Kitchen', 'Puzzles',
    'Weather', 'Architecture', 'Railway', 'Desert', 'Secret Codes',
    'Winter', 'Museum', 'Mystery', 'Astronomy', 'Reasoning',
  ];

  // Authored, offline vocabulary: the same level never changes on reopening.
  static const campaignWordBanks = <List<String>>[
    ['SUSPECT', 'ALIBI', 'MOTIVE', 'WITNESS', 'CLUE', 'PROOF', 'SECRET', 'PUZZLE', 'SHADOW', 'THEORY'],
    ['ORBIT', 'PLANET', 'COMET', 'GALAXY', 'ROCKET', 'NEBULA', 'SOLAR', 'STARS', 'LUNAR', 'ASTEROID'],
    ['CORAL', 'TIDAL', 'REEF', 'SHARK', 'WHALE', 'CURRENT', 'ISLAND', 'SEAWEED', 'DOLPHIN', 'TRENCH'],
    ['PETALS', 'GARDEN', 'FLOWER', 'SEED', 'ROOTS', 'BLOOM', 'ORCHID', 'LEAVES', 'CEDAR', 'WILLOW'],
    ['EMPIRE', 'TEMPLE', 'MARBLE', 'PILLAR', 'SENATE', 'LEGION', 'FORUM', 'MOSAIC', 'ARCH', 'SCROLL'],
    ['RHYTHM', 'MELODY', 'CHORD', 'PIANO', 'VIOLIN', 'GUITAR', 'OPERA', 'DRUM', 'SONATA', 'TEMPO'],
    ['RANGER', 'MAPLE', 'GROVE', 'CANOPY', 'FOXES', 'BADGER', 'HOLLOW', 'MOSS', 'TRAILS', 'FERN'],
    ['ATOM', 'ENERGY', 'LASER', 'GRAVITY', 'MATTER', 'PLASMA', 'NEUTRON', 'ROCKET', 'VAPOR', 'THEORY'],
    ['SPICE', 'GARLIC', 'BREAD', 'NOODLES', 'SOUP', 'GINGER', 'ONION', 'COCONUT', 'WAFFLE', 'PEPPER'],
    ['RIDDLE', 'ENIGMA', 'CODE', 'REASON', 'PATTERN', 'LOGIC', 'HIDDEN', 'SEARCH', 'DECODE', 'CIPHER'],
    ['THUNDER', 'CLOUDS', 'STORM', 'BREEZE', 'RAINBOW', 'FROST', 'SUNNY', 'TORNADO', 'MIST', 'HUMID'],
    ['BRIDGE', 'ARCHWAY', 'SPIRAL', 'FACADE', 'ATRIUM', 'TOWER', 'WINDOWS', 'PILLARS', 'MASON', 'VAULT'],
    ['TUNNEL', 'SIGNAL', 'TRACKS', 'ENGINE', 'STATION', 'ROUTE', 'SWITCH', 'EXPRESS', 'TICKET', 'CABOOSE'],
    ['CACTUS', 'DUNES', 'OASIS', 'SAND', 'MIRAGE', 'CAMEL', 'GECKO', 'VULTURE', 'HAZE', 'SUNSET'],
    ['ENCODE', 'MESSAGE', 'LETTER', 'SYMBOL', 'ROTATE', 'SHIFT', 'MATRIX', 'KEYWORD', 'SECRET', 'DECRYPT'],
    ['FROZEN', 'ICICLE', 'SNOWMAN', 'SKATES', 'SLEIGH', 'BLIZZARD', 'GLOVES', 'SCARF', 'CANDLE', 'COCOA'],
    ['GALLERY', 'FOSSIL', 'ARTIFACT', 'STATUE', 'EXHIBIT', 'CANVAS', 'CURATOR', 'HISTORY', 'RELIC', 'DISPLAY'],
    ['FORENSIC', 'SUSPECT', 'FINGER', 'PRINT', 'DOSSIER', 'EVIDENCE', 'SECRET', 'INQUEST', 'ALIBI', 'TRIAL'],
    ['SATURN', 'JUPITER', 'MERCURY', 'NEPTUNE', 'URANUS', 'VENUS', 'ECLIPSE', 'COSMOS', 'GRAVITY', 'SUNSPOT'],
    ['CONTRAST', 'ANALYZE', 'DEDUCE', 'PREMISE', 'LOGICAL', 'THEOREM', 'OUTCOME', 'PATTERN', 'ABSTRACT', 'PROBLEM'],
  ];

  static int wordsForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, campaignLevelCount, 'level');
    return min(8, 5 + (level - 1) ~/ 6);
  }

  /// Fixed-seed campaign with increasing word counts and direction choices.
  static WordSearchBoard generateCampaignBoard(int level) {
    final target = wordsForLevel(level);
    for (var attempt = 0; attempt < 64; attempt++) {
      final random = Random(level * 104729 + attempt * 8191);
      final candidates = List<String>.of(campaignWordBanks[level - 1])
        ..shuffle(random);
      final board = _generate(
        candidates,
        random: random,
        target: target,
        allowDiagonal: level >= 5,
        allowBackward: level >= 11,
      );
      if (board.words.length == target) return board;
    }
    throw StateError('Unable to place all words for level $level');
  }

  /// Compatibility entry point for existing free-play callers.
  static WordSearchBoard generateBoard(List<String> candidates) => _generate(
        candidates,
        random: Random(),
        target: 8,
        allowDiagonal: true,
        allowBackward: true,
      );

  static WordSearchBoard _generate(
    List<String> candidates, {
    required Random random,
    required int target,
    required bool allowDiagonal,
    required bool allowBackward,
  }) {
    final grid = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    final placed = <WordSearchWord>[];
    final directions = <Point<int>>[const Point(1, 0), const Point(0, 1)];
    if (allowDiagonal) {
      directions.addAll([const Point(1, 1), const Point(1, -1)]);
    }
    if (allowBackward) {
      directions.addAll([for (final dir in List<Point<int>>.of(directions))
        Point(-dir.x, -dir.y)]);
    }
    for (final candidate in candidates) {
      if (placed.length == target) break;
      final word = candidate.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{4,8}$').hasMatch(word) ||
          placed.any((placedWord) => placedWord.word == word)) continue;
      _tryPlaceWord(grid, word, placed, directions, random);
    }
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var y = 0; y < boardSize; y++) {
      for (var x = 0; x < boardSize; x++) {
        if (grid[y][x].isEmpty) {
          grid[y][x] = letters[random.nextInt(letters.length)];
        }
      }
    }
    return WordSearchBoard(size: boardSize, grid: grid, words: placed);
  }

  static bool _tryPlaceWord(
    List<List<String>> grid,
    String word,
    List<WordSearchWord> placed,
    List<Point<int>> directions,
    Random random,
  ) {
    final orderedDirections = List<Point<int>>.of(directions)..shuffle(random);
    final starts = List.generate(boardSize * boardSize, (index) => index)
      ..shuffle(random);
    for (final dir in orderedDirections) {
      for (final start in starts) {
        final x = start % boardSize;
        final y = start ~/ boardSize;
        if (!_canPlace(grid, word, x, y, dir.x, dir.y)) continue;
        final positions = <Point<int>>[];
        for (var i = 0; i < word.length; i++) {
          final px = x + i * dir.x;
          final py = y + i * dir.y;
          grid[py][px] = word[i];
          positions.add(Point(px, py));
        }
        placed.add(WordSearchWord(word: word, positions: positions));
        return true;
      }
    }
    return false;
  }

  static bool _canPlace(
    List<List<String>> grid, String word, int x, int y, int dx, int dy,
  ) {
    final endX = x + (word.length - 1) * dx;
    final endY = y + (word.length - 1) * dy;
    if (endX < 0 || endX >= boardSize || endY < 0 || endY >= boardSize) {
      return false;
    }
    for (var i = 0; i < word.length; i++) {
      final value = grid[y + i * dy][x + i * dx];
      if (value.isNotEmpty && value != word[i]) return false;
    }
    return true;
  }
}
