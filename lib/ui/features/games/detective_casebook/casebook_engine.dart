import 'dart:math';

enum CaseDifficulty { easy, standard, hard }

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
  final bool direct;
  const CaseClue(this.text, this.matches, {this.direct = false});
}

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
    this.difficulty = CaseDifficulty.standard,
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
      id: "night_train", title: "The Night Train Ruby", summary: "The museum ruby vanished during a sleeper-train reception. A witness saw it concealed in a velvet pouch. Identify who carried the pouch, where they visited, and when they arrived.",
      suspects: ["Lena Frost", "Miles Grant", "Priya Shah", "Rowan Lake"], rooms: ["Dining Car", "Sleeper", "Lounge", "Baggage Car"],
      times: ["8:00 PM", "8:15 PM", "8:30 PM", "8:45 PM"], objects: ["Velvet pouch", "Ticket case", "Chess book", "Silver flask"], crimeObject: "Velvet pouch",
      truth: _truth(400), seed: 400,
    ),
    _build(
      id: "opera", title: "The Final Encore", summary: "A singer was found dead after the final curtain. The doctor identified a poisoned goblet. Determine which guest carried it and reconstruct their room and arrival time.",
      suspects: ["Ada Moon", "Bruno West", "Cora Blake", "Damon Finch"], rooms: ["Stage", "Green Room", "Balcony", "Wardrobe"],
      times: ["9:00 PM", "9:20 PM", "9:40 PM", "10:00 PM"], objects: ["Opera glasses", "Poisoned goblet", "Music score", "Silk scarf"], crimeObject: "Poisoned goblet",
      truth: _truth(500), seed: 500,
    ),
    _build(
      id: "snow_lodge", title: "Murder at Snowglass Lodge", summary: "A lodge owner was attacked during a blizzard. Investigators identified an ice pick as the weapon. Four guests each carried one item; find the carrier and their location and time.",
      suspects: ["June Alder", "Kian Birch", "Mina Cedar", "Noel Pine"], rooms: ["Study", "Boot Room", "Sunroom", "Lounge"],
      times: ["5:10 PM", "5:30 PM", "5:50 PM", "6:10 PM"], objects: ["Trail map", "Thermos", "Ice pick", "Wool mittens"], crimeObject: "Ice pick",
      truth: _truth(600), seed: 600,
    ),
    _build(
      id: "observatory", title: "The Blackout at Orion", summary: "The observatory telescope failed before a rare event. Only the person carrying the fuse key could have caused the blackout. Establish their identity, room, and arrival time.",
      suspects: ["Aria North", "Basil Finch", "Cass Vega", "Drew Sol"], rooms: ["Dome", "Workshop", "Control Room", "Roof"],
      times: ["7:00 PM", "7:15 PM", "7:30 PM", "7:45 PM"], objects: ["Star chart", "Fuse key", "Lens cloth", "Notebook"], crimeObject: "Fuse key",
      truth: _truth(700), seed: 700,
    ),
    _build(
      id: "orchard", title: "The Orchard Heirloom", summary: "A family heirloom disappeared at an orchard gathering. The thief carried it away in a blue satchel. Match the visitors to their locations, times, and possessions.",
      suspects: ["Elise Hart", "Finn Reed", "Gia Moss", "Hugo Vale"], rooms: ["Cider House", "Potting Shed", "Veranda", "Glasshouse"],
      times: ["3:00 PM", "3:20 PM", "3:40 PM", "4:00 PM"], objects: ["Blue satchel", "Pruning gloves", "Camera", "Recipe book"], crimeObject: "Blue satchel",
      truth: _truth(800), seed: 800,
    ),
    _build(
      id: "harbor", title: "The Forged Harbor Ledger", summary: "A shipping ledger was replaced with a forgery. The false document bore wax from the red seal carried by one visitor. Who had the seal, and where and when were they recorded?",
      suspects: ["Isla Kent", "Jonah Pike", "Keira Dawn", "Luca Grey"], rooms: ["Chart Room", "Wharf Office", "Warehouse", "Cabin"],
      times: ["4:10 PM", "4:25 PM", "4:40 PM", "4:55 PM"], objects: ["Red seal", "Compass", "Brass token", "Coiled rope"], crimeObject: "Red seal",
      truth: _truth(900), seed: 900,
    ),
  ];

  static final Map<String, DetectiveCase> _difficultyCache = {};
  static CaseAssignment _truth(int seed) {
    final random = Random(seed);
    List<int> permutation() => [0, 1, 2, 3]..shuffle(random);
    return CaseAssignment(permutation(), permutation(), permutation());
  }
  static DetectiveCase caseAt(int index, CaseDifficulty difficulty) {
    if (difficulty == CaseDifficulty.standard) return cases[index];
    final base = cases[index];
    return _difficultyCache.putIfAbsent('$index/${difficulty.name}', () => _build(
      id: base.id, title: base.title, summary: base.summary,
      suspects: base.suspects, rooms: base.rooms, times: base.times, objects: base.objects,
      crimeObject: base.incidentObject, truth: base.solution, seed: (index + 1) * 100,
      difficulty: difficulty,
    ));
  }
  static DetectiveCase daily(DateTime date, CaseDifficulty difficulty) {
    final day = DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ 86400000;
    final base = cases[day % cases.length];
    return _build(
      id: 'daily-${date.year}-${date.month}-${date.day}',
      title: 'Daily: ${base.title}', summary: base.summary,
      suspects: base.suspects, rooms: base.rooms, times: base.times, objects: base.objects,
      crimeObject: base.incidentObject, truth: _truth(day), seed: day,
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
    CaseDifficulty difficulty = CaseDifficulty.standard,
  }) {
    final pool = <CaseClue>[];
    for (var s = 0; s < 4; s++) {
      final suspect = s, room = truth.rooms[s], time = truth.times[s];
      pool.add(CaseClue(
        '${suspects[s]} was seen in the ${rooms[room]}.',
        (a) => a.rooms[suspect] == room, direct: true,
      ));
      pool.add(CaseClue(
        '${suspects[s]} arrived at ${times[time]}.',
        (a) => a.times[suspect] == time, direct: true,
      ));
      for (var item = 0; item < 4; item++) {
        if (item == truth.objects[s]) continue;
        final absentItem = item;
        pool.add(CaseClue(
          '${suspects[s]} did not carry the ${objects[item].toLowerCase()}.',
          (a) => a.objects[suspect] != absentItem,
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
        'The visitor to the ${rooms[room]} carried the '
        '${objects[object].toLowerCase()}.',
        (a) => a.objects[a.rooms.indexOf(place)] == object,
      ));
    }
    for (var time = 0; time < 4; time++) {
      final arrival = time, person = truth.times.indexOf(time);
      final object = truth.objects[person];
      pool.add(CaseClue(
        'The person who arrived at ${times[time]} carried the '
        '${objects[object].toLowerCase()}.',
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

    final shuffled = pool.where((clue) => difficulty != CaseDifficulty.hard || !clue.direct).toList()..shuffle(Random(seed));
    final selected = <CaseClue>[];
    var remaining = List<CaseAssignment>.from(possibilities);

    // Relative alibi plus an exclusion provide useful indirect deductions.
    final relative = shuffled.firstWhere((c) => c.text.contains('arrived before'));
    selected.add(relative);
    remaining = remaining.where(relative.matches).toList();
    shuffled.remove(relative);
    final exclusion = shuffled.firstWhere((c) => c.text.contains('did not carry'));
    selected.add(exclusion);
    remaining = remaining.where(exclusion.matches).toList();
    shuffled.remove(exclusion);

    // Greedily select true clues until there is exactly one full solution.
    // The engine proves uniqueness; it never relies on unverifiable guesses.
    while (remaining.length > 1 && shuffled.isNotEmpty) {
      CaseClue? best;
      List<CaseAssignment>? filtered;
      for (final candidate in shuffled) {
        final next = remaining.where(candidate.matches).toList();
        if (filtered == null || next.length < filtered.length) {
          best = candidate;
          filtered = next;
        }
      }
      if (best == null || filtered == null || filtered.length == remaining.length) {
        throw StateError('Cannot generate a unique case: $id');
      }
      selected.add(best);
      shuffled.remove(best);
      remaining = filtered;
    }
    if (remaining.length != 1) throw StateError('Case is ambiguous: $id');
    if (difficulty == CaseDifficulty.easy) {
      for (final clue in pool.where((clue) => clue.direct).take(4)) {
        if (!selected.any((other) => other.text == clue.text)) selected.add(clue);
      }
    } else if (difficulty == CaseDifficulty.hard) {
      // Keep indirect clues only and remove redundant information, one clue at a time.
      for (var i = selected.length - 1; i >= 0; i--) {
        final reduced = List<CaseClue>.from(selected)..removeAt(i);
        if (possibilities.where((s) => reduced.every((c) => c.matches(s))).take(2).length == 1) {
          selected.removeAt(i);
        }
      }
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
