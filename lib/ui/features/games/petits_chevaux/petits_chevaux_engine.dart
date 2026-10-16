import 'dart:math';
import '../ludo/ludo_engine.dart' show LudoMove, cellFor;

/// French Petits Chevaux. Unlike Ludo, landing on a protected start cell
/// does not prevent captures. Finish the ladder by rolling 1,2,3,4,5,6.
class PetitsChevauxGame {
  PetitsChevauxGame({required List<int> seats, Set<int> computer = const {},
      Random? random})
      : seats = List<int>.unmodifiable(seats),
        computer = Set<int>.unmodifiable(computer),
        rng = random ?? Random(),
        steps = {for (final seat in seats) seat: List<int>.filled(4, -1)},
        current = seats.first {
    if (seats.length < 2 || seats.length > 4 ||
        seats.toSet().length != seats.length ||
        seats.any((s) => s < 0 || s > 3) ||
        computer.any((s) => !seats.contains(s))) {
      throw ArgumentError('Expected 2-4 distinct seats from 0..3');
    }
  }
  final List<int> seats;
  final Set<int> computer;
  final Random rng;
  Map<int, List<int>> steps;
  int current;
  int? dice;
  String message = 'Roll a six to leave the stable';
  final List<int> finishOrder = [];

  bool get over => finishOrder.length >= seats.length - 1;
  bool finished(int seat) => steps[seat]!.every((step) => step == 57);

  List<LudoMove> movesFor(int roll) {
    if (roll < 1 || roll > 6 || over || finished(current)) return [];
    final moves = <LudoMove>[];
    for (var piece = 0; piece < 4; piece++) {
      final from = steps[current]![piece];
      int to;
      if (from < 0) {
        if (roll != 6) continue;
        to = 0;
      } else if (from < 51) {
        to = from + roll;
        if (to > 51) continue;
      } else if (from < 57) {
        if (roll != from - 50) continue;
        to = from + 1;
      } else {
        continue;
      }
      // No stacking friendly horses on the track or home staircase.
      if (to != 57 && steps[current]!.asMap().entries.any((entry) {
        if (entry.key == piece) return false;
        final ownStep = entry.value;
        if (to >= 51) return ownStep == to;
        if (ownStep < 0 || ownStep >= 51) return false;
        final targetCell = cellFor(current, to);
        final existingCell = cellFor(current, ownStep);
        return targetCell[0] == existingCell[0] &&
            targetCell[1] == existingCell[1];
      })) continue;
      final hits = <(int, int)>[];
      if (to < 51) {
        final location = cellFor(current, to);
        for (final other in seats) {
          if (other == current) continue;
          for (var i = 0; i < 4; i++) {
            final step = steps[other]![i];
            if (step < 0 || step >= 51) continue;
            final occupied = cellFor(other, step);
            if (occupied[0] == location[0] && occupied[1] == location[1]) {
              hits.add((other, i));
            }
          }
        }
      }
      moves.add(LudoMove(piece, from, to, captures: hits));
    }
    return moves;
  }

  List<LudoMove> get legalMoves =>
      dice == null ? const [] : movesFor(dice!);

  bool roll({int? fixed}) {
    if (fixed != null && (fixed < 1 || fixed > 6)) {
      throw ArgumentError.value(fixed, 'fixed', 'Die must be 1..6');
    }
    if (over || dice != null) return false;
    final value = fixed ?? rng.nextInt(6) + 1;
    dice = value;
    if (legalMoves.isEmpty) {
      message = 'No horse can move with a $value';
      dice = null;
      _next();
      return false;
    }
    message = 'Rolled $value — choose a highlighted horse';
    return true;
  }

  bool play(int piece) {
    if (over || dice == null) return false;
    final matching = legalMoves.where((m) => m.piece == piece).toList();
    if (matching.isEmpty) return false;
    final move = matching.single;
    steps[current]![piece] = move.to;
    for (final (seat, opponentPiece) in move.captures) {
      steps[seat]![opponentPiece] = -1;
    }
    if (finished(current) && !finishOrder.contains(current)) {
      finishOrder.add(current);
    }
    final again = dice == 6 && !finished(current);
    dice = null;
    message = move.captures.isEmpty ? 'Horse advanced'
        : 'Captured ${move.captures.length} opponent horse(s)';
    if (!over && !again) _next();
    return true;
  }

  void _next() {
    if (over) return;
    var index = seats.indexOf(current);
    do {
      index = (index + 1) % seats.length;
    } while (finished(seats[index]));
    current = seats[index];
  }

  LudoMove choose(int skill) {
    final moves = legalMoves;
    if (moves.isEmpty) throw StateError('No legal move');
    if (skill <= 0) return moves[rng.nextInt(moves.length)];
    double rank(LudoMove m) {
      var score = m.to * .1;
      if (m.from == -1) score += 20;
      score += m.captures.length * 50;
      if (m.to == 57) score += 80;
      if (m.to >= 51) score += 18;
      if (skill >= 2 && m.to < 51) {
        final dest = cellFor(current, m.to);
        for (final other in seats.where((s) => s != current)) {
          for (final enemy in steps[other]!) {
            if (enemy < 0 || enemy >= 51) continue;
            for (var roll = 1; roll <= 6; roll++) {
              if (enemy + roll >= 51) continue;
              final cell = cellFor(other, enemy + roll);
              if (cell[0] == dest[0] && cell[1] == dest[1]) score -= 5;
            }
          }
        }
      }
      return score + rng.nextDouble() * (skill >= 2 ? .25 : 5);
    }
    var best = moves.first, bestScore = double.negativeInfinity;
    for (final m in moves) {
      final score = rank(m);
      if (score > bestScore) {
        best = m;
        bestScore = score;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'seats': List<int>.from(seats),
    'computer': computer.toList()..sort(), 'current': current, 'dice': dice,
    'steps': {for (final s in seats) '$s': List<int>.from(steps[s]!)},
    'finished': List<int>.from(finishOrder), 'message': message,
  };

  factory PetitsChevauxGame.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) throw const FormatException('Unsupported save');
      final seats = List<int>.from(data['seats'] as List);
      final bots = Set<int>.from(data['computer'] as List);
      final game = PetitsChevauxGame(seats: seats, computer: bots);
      final values = Map<String, dynamic>.from(data['steps'] as Map);
      for (final seat in game.seats) {
        game.steps[seat] = List<int>.from(values['$seat'] as List);
      }
      game.current = data['current'] as int;
      game.dice = data['dice'] as int?;
      game.finishOrder.addAll(List<int>.from(data['finished'] as List));
      game.message = data['message'] as String;
      game._validate();
      return game;
    } catch (error) {
      throw FormatException('Invalid Petits Chevaux save: $error');
    }
  }

  void _validate() {
    if (!seats.contains(current) ||
        dice != null && (dice! < 1 || dice! > 6) ||
        finishOrder.toSet().length != finishOrder.length ||
        finishOrder.any((seat) => !seats.contains(seat) || !finished(seat)) ||
        steps.length != seats.length || steps.values.any((values) =>
            values.length != 4 ||
            values.any((n) => n < -1 || n > 57)) ||
        (dice != null && legalMoves.isEmpty) ||
        (over && dice != null) ||
        (!over && finished(current))) {
      throw const FormatException('Illegal turn, horse or dice state');
    }
  }
}
