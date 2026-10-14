import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/detective_casebook/casebook_engine.dart';
import 'package:puzzle/ui/features/games/detective_casebook/case_progress.dart';
void main() {
  test('nine cases are uniquely solvable at every difficulty', () {
    expect(DetectiveCasebook.cases.length, 9);
    for (var i = 0; i < 9; i++) {
      for (final level in CaseDifficulty.values) {
        final game = DetectiveCasebook.caseAt(i, level);
        expect(game.countSolutions(), 1, reason: '${game.id}/$level');
        expect(game.clues.every((clue) => clue.matches(game.solution)), true);
        if (level == CaseDifficulty.hard) expect(game.clues.any((clue) => clue.direct), false);
      }
      expect(DetectiveCasebook.caseAt(i, CaseDifficulty.easy).clues.length,
        greaterThanOrEqualTo(DetectiveCasebook.cases[i].clues.length));
    }
  });
  test('daily case is deterministic and uniquely solvable', () {
    for (var day = 1; day <= 7; day++) {
      for (final level in CaseDifficulty.values) {
        final a = DetectiveCasebook.daily(DateTime(2026, 10, day), level);
        final b = DetectiveCasebook.daily(DateTime(2026, 10, day, 23, 59), level);
        expect(a.clues.map((c) => c.text), b.clues.map((c) => c.text));
        expect(a.countSolutions(), 1);
      }
    }
  });
  test('notebook persists clues, notes, hints and full conclusion', () {
    final game = DetectiveCasebook.cases.first;
    final p = CaseProgress()..cycle('Rooms/0/1')..checked.add(0)..hints = 2;
    p.accusation = game.culprit; p.room = game.rooms[game.incidentRoomIndex]; p.time = game.times[game.incidentTimeIndex];
    expect(p.submit(game), true);
    final restored = CaseProgress.fromJson(p.toJson(), game);
    expect(restored.notes, p.notes); expect(restored.checked, p.checked); expect(restored.solved, true);
  });
  test('a revealed answer is not counted as a solved case', () {
    final game = DetectiveCasebook.cases.first;
    final p = CaseProgress()..revealed = true;
    p.accusation = game.culprit; p.room = game.rooms[game.incidentRoomIndex]; p.time = game.times[game.incidentTimeIndex];
    expect(p.submit(game), false);
  });
  test('invalid notebook keys are rejected', () {
    final data = CaseProgress().toJson(); data['notes'] = {'Rooms/5/1': 2};
    expect(() => CaseProgress.fromJson(data, DetectiveCasebook.cases.first), throwsFormatException);
  });
}
