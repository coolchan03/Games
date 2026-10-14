import 'casebook_engine.dart';

class CaseProgress {
  final Set<int> checked = {};
  final Map<String, int> notes = {};
  int hints = 0;
  String? accusation, room, time;
  bool solved = false, revealed = false;
  CaseProgress();
  void cycle(String key) { notes[key] = ((notes[key] ?? 0) + 1) % 3; }
  bool submit(DetectiveCase game) {
    solved = !revealed && accusation == game.culprit &&
      room == game.rooms[game.incidentRoomIndex] && time == game.times[game.incidentTimeIndex];
    return solved;
  }
  Map<String, dynamic> toJson() => {'version': 1, 'checked': checked.toList(),
    'notes': Map<String, int>.from(notes), 'hints': hints, 'accusation': accusation,
    'room': room, 'time': time, 'solved': solved, 'revealed': revealed};
  factory CaseProgress.fromJson(Map<String, dynamic> data, DetectiveCase game) {
    if (data['version'] != 1) throw const FormatException('Unsupported notebook');
    final p = CaseProgress();
    p.checked.addAll(List<int>.from(data['checked'] as List));
    p.notes.addAll(Map<String, int>.from(data['notes'] as Map));
    p.hints = data['hints'] as int; p.accusation = data['accusation'] as String?;
    p.room = data['room'] as String?; p.time = data['time'] as String?;
    p.solved = data['solved'] as bool; p.revealed = data['revealed'] as bool;
    if (p.hints < 0 || p.hints > 3 || p.checked.any((i) => i < 0 || i >= game.clues.length) ||
        p.notes.entries.any((e) => !RegExp(r'^(Rooms|Times|Objects)/[0-3]/[0-3]$').hasMatch(e.key) || e.value < 0 || e.value > 2) ||
        (p.accusation != null && !game.suspects.contains(p.accusation)) ||
        (p.room != null && !game.rooms.contains(p.room)) || (p.time != null && !game.times.contains(p.time)) ||
        (p.solved && (p.revealed || p.accusation != game.culprit || p.room != game.rooms[game.incidentRoomIndex] || p.time != game.times[game.incidentTimeIndex]))) {
      throw const FormatException('Invalid notebook progress');
    }
    return p;
  }
}
