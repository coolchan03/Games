import 'dart:math';

/// A compact offline logic-grid solver for original whodunit cases.
/// All people have unique rooms, arrival times, and objects.
class CaseAssignment {
  final List<int> rooms;
  final List<int> times;
  final List<int> objects;
  const CaseAssignment(this.rooms, this.times, this.objects);
}

class CaseClue {
  final String text;
  final bool Function(CaseAssignment) matches;

  /// Direct clues state a single fact about one suspect ("X was in the
  /// Library"); hard cases use only indirect reasoning.
  final bool direct;
  const CaseClue(this.text, this.matches, {this.direct = false});
}

enum CaseDifficulty { easy, hard }

class DetectiveCase {
  final String id, title, summary;
  final String incidentObject;
  final List<String> suspects, rooms, times, objects;
  final CaseAssignment solution;
  final List<CaseClue> clues;
  final CaseDifficulty difficulty;
  const DetectiveCase({
    required this.id,
    required this.title,
    required this.summary,
    required this.incidentObject,
    required this.suspects,
    required this.rooms,
    required this.times,
    required this.objects,
    required this.solution,
    required this.clues,
    this.difficulty = CaseDifficulty.easy,
  });
  int get culpritIndex => solution.objects.indexOf(objects.indexOf(incidentObject));
  String get culprit => suspects[culpritIndex];
  int get incidentTimeIndex => solution.times[culpritIndex];
  int get incidentRoomIndex => solution.rooms[culpritIndex];
  bool accuse(String person) => person == culprit;

  /// Returns count of full assignments consistent with all displayed clues.
  int countSolutions() => DetectiveCasebook.possibilities
      .where((s) => clues.every((c) => c.matches(s))).length;
}

/// Themes for procedurally generated cases. Every generated case is checked
/// by the solver to have exactly one consistent assignment.
class _Theme {
  const _Theme(this.place, this.crime, this.verb, this.rooms, this.times, this.objects, this.evidence);
  final String place, crime, verb;
  final List<String> rooms, times, objects;
  final String evidence;
}

const _firstNames = [
  'Ada', 'Basil', 'Cora', 'Dmitri', 'Esme', 'Felix', 'Greta', 'Hugo', 'Ines', 'Jasper',
  'Kira', 'Lionel', 'Mina', 'Nestor', 'Olive', 'Pavel', 'Quinn', 'Rosa', 'Silas', 'Tamsin',
  'Ulric', 'Vera', 'Wren', 'Xavier', 'Yara', 'Zane',
];
const _lastNames = [
  'Ashdown', 'Blackwood', 'Carrow', 'Delacroix', 'Ember', 'Fairweather', 'Grimsby', 'Holloway',
  'Ingram', 'Jessop', 'Kettering', 'Lockhart', 'Moreau', 'Nightingale', 'Okafor', 'Pemberton',
  'Quayle', 'Rookwood', 'Sterling', 'Thorne', 'Underhill', 'Vance', 'Whitlock', 'Yardley',
];

const _themes = [
  _Theme('a lighthouse', 'The keeper\'s logbook was burned', 'burned the logbook',
      ['Lamp Room', 'Stairwell', 'Boathouse', 'Cottage'], ['7:00 PM', '7:15 PM', '7:30 PM', '7:45 PM'],
      ['Matchbox', 'Oil can', 'Rope', 'Spyglass'], 'Matchbox'),
  _Theme('a mountain observatory', 'The star charts were stolen', 'stole the charts',
      ['Dome', 'Library', 'Kitchen', 'Radio Room'], ['10:00 PM', '10:20 PM', '10:40 PM', '11:00 PM'],
      ['Satchel', 'Thermos', 'Notebook', 'Torch'], 'Satchel'),
  _Theme('a vineyard estate', 'The prize vintage was poisoned', 'poisoned the wine',
      ['Cellar', 'Press House', 'Veranda', 'Tasting Room'], ['4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM'],
      ['Dropper bottle', 'Corkscrew', 'Ledger', 'Pruning shears'], 'Dropper bottle'),
  _Theme('a steam train', 'The courier\'s diamond vanished', 'took the diamond',
      ['Dining Car', 'Sleeper', 'Baggage Car', 'Observation Deck'], ['1:05 AM', '1:20 AM', '1:35 AM', '1:50 AM'],
      ['Velvet pouch', 'Ticket punch', 'Umbrella', 'Hip flask'], 'Velvet pouch'),
  _Theme('a natural history museum', 'A fossil was smashed', 'smashed the fossil',
      ['Dinosaur Hall', 'Gift Shop', 'Archive', 'Café'], ['2:00 PM', '2:15 PM', '2:30 PM', '2:45 PM'],
      ['Geologist\'s hammer', 'Guidebook', 'Camera', 'Lanyard'], 'Geologist\'s hammer'),
  _Theme('a snowbound chalet', 'The heating was sabotaged', 'cut the fuel line',
      ['Boiler Room', 'Lounge', 'Ski Room', 'Attic'], ['6:10 AM', '6:25 AM', '6:40 AM', '6:55 AM'],
      ['Wire cutters', 'Ski wax', 'Blanket', 'Thermometer'], 'Wire cutters'),
  _Theme('a botanical garden', 'The rare orchid was uprooted', 'uprooted the orchid',
      ['Palm House', 'Potting Shed', 'Herb Garden', 'Pond'], ['8:00 AM', '8:20 AM', '8:40 AM', '9:00 AM'],
      ['Trowel', 'Watering can', 'Seed packet', 'Sketchbook'], 'Trowel'),
  _Theme('a theatre', 'The leading lady\'s costume was slashed', 'slashed the costume',
      ['Dressing Room', 'Fly Gallery', 'Box Office', 'Orchestra Pit'], ['7:05 PM', '7:20 PM', '7:35 PM', '7:50 PM'],
      ['Scissors', 'Script', 'Opera glasses', 'Tuning fork'], 'Scissors'),
];

class DetectiveCasebook {
  static final List<List<int>> _permutations = _buildPermutations();
  static final List<CaseAssignment> possibilities = [
    for (final r in _permutations)
      for (final t in _permutations)
        for (final o in _permutations)
          CaseAssignment(r, t, o),
  ];
  static List<List<int>> _buildPermutations() {
    final result = <List<int>>[];
    void visit(List<int> current, List<int> unused) {
      if (unused.isEmpty) {
        result.add(List<int>.from(current));
        return;
      }
      for (final x in unused) {
        visit([...current, x], unused.where((e) => e != x).toList());
      }
    }
    visit([], [0, 1, 2, 3]);
    return result;
  }

  static final List<DetectiveCase> cases = [
    _build(
      id: 'clocktower',
      title: 'The Clocktower Murder',
      summary: 'Curator Felix Vale was found dead after a private tour. '
          'The medical examiner identified the letter opener as the weapon. '
          'Four guests each visited a different room at a different time '
          'and carried a different object. Who held the weapon?',
      suspects: ['Nora Bell', 'Elias Marsh', 'Iris Stone', 'Theo Quinn'],
      rooms: ['Library', 'Greenhouse', 'Gallery', 'Clocktower'],
      times: ['9:10 PM', '9:30 PM', '9:50 PM', '10:10 PM'],
      objects: ['Brass key', 'Pocket watch', 'Letter opener', 'Lantern'],
      crimeObject: 'Letter opener',
      truth: const CaseAssignment([2, 0, 3, 1], [1, 3, 2, 0], [3, 0, 2, 1]),
      seed: 100,
    ),
    _build(
      id: 'blue_room',
      title: 'The Blue Room Theft',
      summary: 'An irreplaceable painting disappeared during a reception. '
          'The thief left with it inside a canvas tube. Four visitors were '
          'logged in different rooms and times, each carrying one item. '
          'Who took the painting?',
      suspects: ['Ava Reed', 'Ben Carver', 'Cleo Voss', 'Dylan Price'],
      rooms: ['Atrium', 'Blue Room', 'Terrace', 'Archive'],
      times: ['6:00 PM', '6:20 PM', '6:40 PM', '7:00 PM'],
      objects: ['Canvas tube', 'Keycard', 'Flashlight', 'Gloves'],
      crimeObject: 'Canvas tube',
      truth: const CaseAssignment([1, 3, 0, 2], [2, 0, 3, 1], [2, 3, 1, 0]),
      seed: 200,
    ),
    _build(
      id: 'banquet',
      title: 'Poison at the Banquet',
      summary: 'A diplomat collapsed at a midnight banquet. '
          'A poison vial was identified as the source. Four guests each '
          'moved through one room, arrived at a distinct time, and held '
          'a different item. Who brought the vial?',
      suspects: ['Mara Finch', 'Owen Pike', 'Sofia Crane', 'Victor Hale'],
      rooms: ['Kitchen', 'Ballroom', 'Pantry', 'Wine Cellar'],
      times: ['11:10 PM', '11:25 PM', '11:40 PM', '11:55 PM'],
      objects: ['Poison vial', 'Silver tray', 'Wine decanter', 'Sealed note'],
      crimeObject: 'Poison vial',
      truth: const CaseAssignment([3, 1, 0, 2], [1, 3, 2, 0], [1, 3, 0, 2]),
      seed: 300,
    ),
    _build(
      id: 'regatta',
      title: 'Sabotage at the Regatta',
      summary: 'Minutes before the final race, the favourite\'s rudder cable '
          'was cut. The harbourmaster found a hacksaw blade in the water. '
          'Four crew members each went to one place at one time, carrying '
          'one thing. Who held the hacksaw?',
      suspects: ['Hattie Lowe', 'Rafe Dunmore', 'Pippa Shaw', 'Callum Fry'],
      rooms: ['Boathouse', 'Jetty', 'Clubhouse', 'Sail Loft'],
      times: ['8:05 AM', '8:15 AM', '8:25 AM', '8:35 AM'],
      objects: ['Hacksaw', 'Life vest', 'Compass', 'Thermos'],
      crimeObject: 'Hacksaw',
      truth: const CaseAssignment([0, 2, 3, 1], [3, 1, 0, 2], [2, 0, 3, 1]),
      seed: 400,
    ),
    _build(
      id: 'manuscript',
      title: 'The Vanishing Manuscript',
      summary: 'A first-edition manuscript disappeared from a locked study. '
          'Whoever took it slipped it into a leather portfolio. Four '
          'scholars each visited one room at one time with one item. '
          'Who carried the portfolio?',
      suspects: ['Agnes Wilde', 'Bertram Cole', 'Daphne Rook', 'Edmund Hale'],
      rooms: ['Study', 'Reading Room', 'Conservatory', 'Map Room'],
      times: ['3:00 PM', '3:20 PM', '3:40 PM', '4:00 PM'],
      objects: ['Leather portfolio', 'Magnifying glass', 'Fountain pen', 'Tea cup'],
      crimeObject: 'Leather portfolio',
      truth: const CaseAssignment([1, 3, 0, 2], [0, 2, 3, 1], [3, 0, 2, 1]),
      seed: 500,
      difficulty: CaseDifficulty.hard,
    ),
    _build(
      id: 'circus',
      title: 'The Ringmaster\'s Fall',
      summary: 'The ringmaster fell when his trapeze rope gave way. Fibres '
          'on a utility knife prove the rope was cut. Four performers were '
          'each backstage in one place at one time with one prop. Who had '
          'the knife?',
      suspects: ['Lola Brightwater', 'Marco Vitti', 'Sasha Orlov', 'Ted Bramble'],
      rooms: ['Big Top', 'Menagerie', 'Wagon Row', 'Costume Tent'],
      times: ['5:10 PM', '5:25 PM', '5:40 PM', '5:55 PM'],
      objects: ['Utility knife', 'Juggling clubs', 'Top hat', 'Whistle'],
      crimeObject: 'Utility knife',
      truth: const CaseAssignment([2, 0, 1, 3], [1, 0, 3, 2], [0, 2, 1, 3]),
      seed: 600,
    ),
    _build(
      id: 'embassy',
      title: 'Secrets at the Embassy',
      summary: 'A coded cable was photographed and leaked. The spy used a '
          'miniature camera. Four attachés each visited one office at one '
          'time and carried one item. Who had the camera?',
      suspects: ['Clara Voight', 'Anton Belov', 'Mei Tanaka', 'Jules Ferrand'],
      rooms: ['Cipher Room', 'Ballroom', 'Courtyard', 'Press Office'],
      times: ['10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM'],
      objects: ['Miniature camera', 'Briefcase', 'Cigarette case', 'Umbrella'],
      crimeObject: 'Miniature camera',
      truth: const CaseAssignment([3, 0, 2, 1], [2, 3, 0, 1], [1, 3, 0, 2]),
      seed: 700,
      difficulty: CaseDifficulty.hard,
    ),
    _build(
      id: 'bakery',
      title: 'The Bake-Off Scandal',
      summary: 'The champion\'s showpiece cake was ruined with salt. A salt '
          'shaker was found smeared with icing. Four bakers each spent time '
          'in one area at one time, holding one tool. Who had the shaker?',
      suspects: ['Poppy Lane', 'Gus Mackay', 'Hana Ito', 'Rory Blake'],
      rooms: ['Pantry', 'Oven Bay', 'Judging Table', 'Walk-in Fridge'],
      times: ['1:00 PM', '1:10 PM', '1:20 PM', '1:30 PM'],
      objects: ['Salt shaker', 'Piping bag', 'Whisk', 'Rolling pin'],
      crimeObject: 'Salt shaker',
      truth: const CaseAssignment([0, 3, 1, 2], [2, 1, 0, 3], [2, 1, 3, 0]),
      seed: 800,
    ),
    _build(
      id: 'museum_night',
      title: 'A Night at the Gallery',
      summary: 'A sculpture was swapped for a forgery overnight. The forger '
          'carried the fake in a padded crate. Four night staff each '
          'checked one gallery at one time and had one item. Who moved the '
          'crate?',
      suspects: ['Imogen Pryce', 'Kofi Mensah', 'Lars Eklund', 'Nadia Farouk'],
      rooms: ['Sculpture Court', 'Loading Dock', 'Security Office', 'East Wing'],
      times: ['12:15 AM', '12:45 AM', '1:15 AM', '1:45 AM'],
      objects: ['Padded crate', 'Radio', 'Key ring', 'Flashlight'],
      crimeObject: 'Padded crate',
      truth: const CaseAssignment([1, 2, 3, 0], [3, 0, 1, 2], [3, 1, 0, 2]),
      seed: 900,
      difficulty: CaseDifficulty.hard,
    ),
    _build(
      id: 'chess_club',
      title: 'Checkmate at the Chess Club',
      summary: 'The trophy was stolen from the chess club during the '
          'tournament. It left the building in a sports bag. Four players '
          'each stepped away to one place at one time with one belonging. '
          'Who carried the sports bag?',
      suspects: ['Boris Kalin', 'Edith Marsh', 'Faisal Rahman', 'Gwen Talbot'],
      rooms: ['Trophy Cabinet', 'Analysis Room', 'Cloakroom', 'Car Park'],
      times: ['2:10 PM', '2:20 PM', '2:30 PM', '2:40 PM'],
      objects: ['Sports bag', 'Chess clock', 'Scorebook', 'Sandwich'],
      crimeObject: 'Sports bag',
      truth: const CaseAssignment([2, 3, 0, 1], [0, 3, 1, 2], [1, 2, 0, 3]),
      seed: 1000,
    ),
    _build(
      id: 'lab',
      title: 'The Laboratory Leak',
      summary: 'A prototype formula was copied from the research lab. The '
          'thief used a USB drive later found in a coat pocket. Four '
          'researchers each visited one room at one time with one item. '
          'Who had the drive?',
      suspects: ['Dr. Ilse Brandt', 'Dr. Omar Haddad', 'Dr. Lucy Chen', 'Dr. Peter Novak'],
      rooms: ['Clean Room', 'Server Closet', 'Canteen', 'Director\'s Office'],
      times: ['9:00 AM', '9:15 AM', '9:30 AM', '9:45 AM'],
      objects: ['USB drive', 'Lab coat', 'Pipette', 'Coffee mug'],
      crimeObject: 'USB drive',
      truth: const CaseAssignment([1, 0, 3, 2], [2, 3, 1, 0], [0, 3, 2, 1]),
      seed: 1100,
      difficulty: CaseDifficulty.hard,
    ),
    _build(
      id: 'castle',
      title: 'The Ghost of Hollow Castle',
      summary: 'Guests at Hollow Castle were terrified by a "ghost" — a '
          'prankster in a white sheet who smashed a priceless vase. The '
          'sheet was found balled up in a corridor. Four guests each '
          'wandered one room at one time carrying one thing. Who wore the '
          'sheet?',
      suspects: ['Lady Ottoline', 'Sir Reginald', 'Miss Primrose', 'Captain Ward'],
      rooms: ['Great Hall', 'Armoury', 'Chapel', 'North Tower'],
      times: ['11:00 PM', '11:30 PM', '12:00 AM', '12:30 AM'],
      objects: ['White sheet', 'Candlestick', 'Shawl', 'Pipe'],
      crimeObject: 'White sheet',
      truth: const CaseAssignment([3, 1, 2, 0], [1, 2, 3, 0], [2, 0, 1, 3]),
      seed: 1200,
    ),
  ];

  /// A 20-case offline campaign. The first 12 chapters are authored and the
  /// final eight use fixed seeds and distinct locations. Every generated
  /// chapter goes through the same uniqueness-checked logic solver.
  static const int campaignCount = 20;
  static final Map<int, DetectiveCase> _campaignCache = {};

  static String campaignTitle(int index) {
    RangeError.checkValueInInterval(index, 0, campaignCount - 1, 'index');
    if (index < cases.length) return cases[index].title;
    return _themes[index - cases.length].crime;
  }

  static DetectiveCase campaignCase(int index) {
    RangeError.checkValueInInterval(index, 0, campaignCount - 1, 'index');
    if (index < cases.length) return cases[index];
    return _campaignCache.putIfAbsent(index, () {
      final chapter = index - cases.length;
      return generate(
        130001 + chapter * 577,
        themeIndex: chapter,
        difficulty: chapter < 4 ? CaseDifficulty.easy : CaseDifficulty.hard,
      );
    });
  }

  /// A generated case. The same [seed] always produces the same case, so it
  /// can serve as a shared daily puzzle.
  static DetectiveCase generate(int seed, {
    CaseDifficulty difficulty = CaseDifficulty.easy,
    int? themeIndex,
  }) {
    final rng = Random(seed);
    final theme = _themes[themeIndex == null
        ? rng.nextInt(_themes.length)
        : themeIndex % _themes.length];
    final first = _firstNames.toList()..shuffle(rng);
    final last = _lastNames.toList()..shuffle(rng);
    final suspects = [for (var i = 0; i < 4; i++) '${first[i]} ${last[i]}'];
    final perms = _permutations;
    final truth = CaseAssignment(
      perms[rng.nextInt(perms.length)],
      perms[rng.nextInt(perms.length)],
      perms[rng.nextInt(perms.length)],
    );
    return _build(
      id: 'generated_$seed',
      title: 'Case #$seed: ${theme.crime}',
      summary: 'At ${theme.place}: ${theme.crime}. The culprit used the '
          '${theme.evidence.toLowerCase()}. Four people each visited one '
          'place at one time and carried one item. Who ${theme.verb}?',
      suspects: suspects,
      rooms: theme.rooms,
      times: theme.times,
      objects: theme.objects,
      crimeObject: theme.evidence,
      truth: truth,
      seed: seed,
      difficulty: difficulty,
    );
  }

  static DetectiveCase _build({
    required String id,
    required String title,
    required String summary,
    required List<String> suspects,
    required List<String> rooms,
    required List<String> times,
    required List<String> objects,
    required String crimeObject,
    required CaseAssignment truth,
    required int seed,
    CaseDifficulty difficulty = CaseDifficulty.easy,
  }) {
    String low(String s) => s.toLowerCase();
    final pool = <CaseClue>[];
    for (var s = 0; s < 4; s++) {
      final suspect = s, room = truth.rooms[s], time = truth.times[s];
      pool.add(CaseClue(
        '${suspects[s]} was seen in the ${rooms[room]}.',
        (a) => a.rooms[suspect] == room,
        direct: true,
      ));
      pool.add(CaseClue(
        '${suspects[s]} arrived at ${times[time]}.',
        (a) => a.times[suspect] == time,
        direct: true,
      ));
      for (var item = 0; item < 4; item++) {
        if (item == truth.objects[s]) continue;
        final absentItem = item;
        pool.add(CaseClue(
          '${suspects[s]} did not carry the ${low(objects[item])}.',
          (a) => a.objects[suspect] != absentItem,
        ));
      }
      for (var r = 0; r < 4; r++) {
        if (r == room) continue;
        final absentRoom = r;
        pool.add(CaseClue(
          '${suspects[s]} never went into the ${rooms[r]}.',
          (a) => a.rooms[suspect] != absentRoom,
        ));
      }
    }
    for (var room = 0; room < 4; room++) {
      final place = room, person = truth.rooms.indexOf(room);
      final time = truth.times[person], object = truth.objects[person];
      pool.add(CaseClue(
        'The visitor to the ${rooms[room]} arrived at ${times[time]}.',
        (a) => a.times[a.rooms.indexOf(place)] == time,
      ));
      pool.add(CaseClue(
        'The visitor to the ${rooms[room]} carried the ${low(objects[object])}.',
        (a) => a.objects[a.rooms.indexOf(place)] == object,
      ));
      for (var o = 0; o < 4; o++) {
        if (o == object) continue;
        final absent = o;
        pool.add(CaseClue(
          'The ${low(objects[o])} was never in the ${rooms[room]}.',
          (a) => a.objects[a.rooms.indexOf(place)] != absent,
        ));
      }
    }
    for (var time = 0; time < 4; time++) {
      final arrival = time, person = truth.times.indexOf(time);
      final object = truth.objects[person];
      pool.add(CaseClue(
        'The person who arrived at ${times[time]} carried the ${low(objects[object])}.',
        (a) => a.objects[a.times.indexOf(arrival)] == object,
      ));
    }
    for (var a = 0; a < 4; a++) {
      for (var b = a + 1; b < 4; b++) {
        final first = truth.times[a] < truth.times[b] ? a : b;
        final second = first == a ? b : a;
        pool.add(CaseClue(
          '${suspects[first]} arrived before ${suspects[second]}.',
          (s) => s.times[first] < s.times[second],
        ));
      }
    }
    // Relative timing between places and items.
    for (var r1 = 0; r1 < 4; r1++) {
      for (var r2 = r1 + 1; r2 < 4; r2++) {
        final p1 = truth.rooms.indexOf(r1), p2 = truth.rooms.indexOf(r2);
        final early = truth.times[p1] < truth.times[p2] ? r1 : r2;
        final late = early == r1 ? r2 : r1;
        pool.add(CaseClue(
          'Whoever was in the ${rooms[early]} arrived earlier than whoever was in the ${rooms[late]}.',
          (s) => s.times[s.rooms.indexOf(early)] < s.times[s.rooms.indexOf(late)],
        ));
      }
    }
    for (var o1 = 0; o1 < 4; o1++) {
      for (var o2 = o1 + 1; o2 < 4; o2++) {
        final p1 = truth.objects.indexOf(o1), p2 = truth.objects.indexOf(o2);
        final early = truth.times[p1] < truth.times[p2] ? o1 : o2;
        final late = early == o1 ? o2 : o1;
        pool.add(CaseClue(
          'The ${low(objects[early])} arrived before the ${low(objects[late])}.',
          (s) => s.times[s.objects.indexOf(early)] < s.times[s.objects.indexOf(late)],
        ));
      }
    }
    // "Either/or" statements.
    for (var s = 0; s < 4; s++) {
      final real = truth.rooms[s];
      final decoy = (real + 1 + (seed + s) % 3) % 4;
      final suspect = s;
      final pair = [real, decoy]..sort();
      pool.add(CaseClue(
        '${suspects[s]} was either in the ${rooms[pair[0]]} or the ${rooms[pair[1]]}.',
        (a) => a.rooms[suspect] == pair[0] || a.rooms[suspect] == pair[1],
      ));
    }

    if (difficulty == CaseDifficulty.hard) {
      pool.removeWhere((c) => c.direct);
    }
    final shuffled = List<CaseClue>.from(pool)..shuffle(Random(seed));
    final selected = <CaseClue>[];
    var remaining = List<CaseAssignment>.from(possibilities);

    // Relative alibi plus an exclusion provide useful indirect deductions.
    for (final kind in ['arrived before', 'did not carry', 'either in']) {
      final clue = shuffled.firstWhere((c) => c.text.contains(kind));
      selected.add(clue);
      remaining = remaining.where(clue.matches).toList();
      shuffled.remove(clue);
    }

    // Greedily select true clues until there is exactly one full solution.
    // Hard cases pick the clue that eliminates the least (but some) options
    // among the better half, giving longer chains of reasoning.
    final rng = Random(seed + 7);
    while (remaining.length > 1 && shuffled.isNotEmpty) {
      final scored = <(CaseClue, List<CaseAssignment>)>[];
      for (final candidate in shuffled) {
        final next = remaining.where(candidate.matches).toList();
        if (next.length < remaining.length) scored.add((candidate, next));
      }
      if (scored.isEmpty) throw StateError('Cannot generate a unique case: $id');
      scored.sort((a, b) => a.$2.length.compareTo(b.$2.length));
      final pickFrom = difficulty == CaseDifficulty.hard ? max(1, scored.length ~/ 3) : 1;
      final (best, filtered) = scored[rng.nextInt(pickFrom)];
      selected.add(best);
      shuffled.remove(best);
      remaining = filtered;
    }
    if (remaining.length != 1) throw StateError('Case is ambiguous: $id');
    // Drop clues that turned out to be redundant (keeps cases tight).
    final masks = {for (final c in selected) c: [for (final p in possibilities) c.matches(p)]};
    for (final c in selected.toList()) {
      final others = [for (final x in selected) if (x != c) masks[x]!];
      var count = 0;
      for (var i = 0; i < possibilities.length && count < 2; i++) {
        if (others.every((m) => m[i])) count++;
      }
      if (count == 1) selected.remove(c);
    }
    selected.shuffle(Random(seed + 1));
    return DetectiveCase(
      id: id, title: title, summary: summary,
      incidentObject: crimeObject,
      suspects: suspects, rooms: rooms, times: times, objects: objects,
      solution: truth, clues: selected, difficulty: difficulty,
    );
  }
}
