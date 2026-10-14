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
  const CaseClue(this.text, this.matches);
}

class DetectiveCase {
  final String id, title, summary;
  final String incidentObject;
  final List<String> suspects, rooms, times, objects;
  final CaseAssignment solution;
  final List<CaseClue> clues;
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
  ];

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
  }) {
    final pool = <CaseClue>[];
    for (var s = 0; s < 4; s++) {
      final suspect = s, room = truth.rooms[s], time = truth.times[s];
      pool.add(CaseClue(
        '${suspects[s]} was seen in the ${rooms[room]}.',
        (a) => a.rooms[suspect] == room,
      ));
      pool.add(CaseClue(
        '${suspects[s]} arrived at ${times[time]}.',
        (a) => a.times[suspect] == time,
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

    final shuffled = List<CaseClue>.from(pool)..shuffle(Random(seed));
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
    selected.shuffle(Random(seed + 1));
    return DetectiveCase(
      id: id, title: title, summary: summary,
      incidentObject: crimeObject,
      suspects: suspects, rooms: rooms, times: times, objects: objects,
      solution: truth, clues: selected,
    );
  }
}
