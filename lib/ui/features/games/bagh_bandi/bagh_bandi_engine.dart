import 'dart:math';

import '../common/alquerque_board.dart';

/// Bengali Bagh Bandi: TWO tigers and FOUR initial stacks of five goats.
/// This is a different game from the existing four-tiger Bagh Chal.
enum BandiSide { goats, tigers }
enum BandiOutcome { ongoing, goats, tigers, draw }

class BandiMove {
  const BandiMove({required this.from, required this.to, this.capture});
  final int from;
  final int to;
  final int? capture;

  @override
  bool operator ==(Object other) => other is BandiMove &&
      from == other.from && to == other.to && capture == other.capture;
  @override
  int get hashCode => Object.hash(from, to, capture);
  @override
  String toString() => 'BandiMove($from->$to, capture:$capture)';
}

class BaghBandiGame {
  BaghBandiGame()
      : goats = List<int>.filled(25, 0),
        tigers = <int>{7, 17} {
    for (final cell in [1, 3, 11, 13]) {
      goats[cell] = 5;
    }
  }

  BaghBandiGame._(this.goats, this.tigers, this.turn, this.captured,
      this.quietMoves);

  final List<int> goats;
  final Set<int> tigers;
  BandiSide turn = BandiSide.goats;
  int captured = 0;
  int quietMoves = 0;

  int get goatsLeft => goats.fold<int>(0, (sum, n) => sum + n);

  BaghBandiGame copy() => BaghBandiGame._(
      List<int>.from(goats), Set<int>.from(tigers), turn, captured, quietMoves);

  List<BandiMove> movesFor(BandiSide side) {
    final result = <BandiMove>[];
    if (side == BandiSide.goats) {
      for (var from = 0; from < 25; from++) {
        if (goats[from] == 0) continue;
        for (final (dx, dy) in AlquerqueGeometry.dirs(from)) {
          final to = AlquerqueGeometry.step(from, dx, dy);
          if (to != null && goats[to] == 0 && !tigers.contains(to)) {
            result.add(BandiMove(from: from, to: to));
          }
        }
      }
    } else {
      for (final from in tigers) {
        for (final (dx, dy) in AlquerqueGeometry.dirs(from)) {
          final next = AlquerqueGeometry.step(from, dx, dy);
          if (next == null || tigers.contains(next)) continue;
          if (goats[next] == 0) {
            result.add(BandiMove(from: from, to: next));
          } else {
            final landing = AlquerqueGeometry.step(from, dx, dy, 2);
            if (landing != null && goats[landing] == 0 &&
                !tigers.contains(landing)) {
              result.add(BandiMove(from: from, to: landing, capture: next));
            }
          }
        }
      }
    }
    return result;
  }

  List<BandiMove> get legalMoves =>
      outcome == BandiOutcome.ongoing ? movesFor(turn) : const <BandiMove>[];

  /// Returns the winner, or a draw after 100 consecutive non-capture moves.
  /// Classical descriptions leave the tiger capture threshold unspecified:
  /// this rule set requires the tigers to remove every goat (or block goats).
  BandiOutcome get outcome {
    if (goatsLeft == 0 && captured == 20) return BandiOutcome.tigers;
    if (movesFor(BandiSide.tigers).isEmpty) return BandiOutcome.goats;
    if (turn == BandiSide.goats && movesFor(BandiSide.goats).isEmpty) {
      return BandiOutcome.tigers;
    }
    if (quietMoves >= 100) return BandiOutcome.draw;
    return BandiOutcome.ongoing;
  }

  bool move(BandiMove move) {
    if (outcome != BandiOutcome.ongoing || !movesFor(turn).contains(move)) {
      return false;
    }
    if (turn == BandiSide.goats) {
      goats[move.from]--;
      goats[move.to]++;
      quietMoves++;
      turn = BandiSide.tigers;
    } else {
      tigers.remove(move.from);
      tigers.add(move.to);
      if (move.capture != null) {
        goats[move.capture!]--;
        captured++;
        quietMoves = 0;
      } else {
        quietMoves++;
      }
      turn = BandiSide.goats;
    }
    return true;
  }

  /// Original lightweight AI with a distinct look-ahead for harder settings.
  BandiMove chooseMove(Random random, {int level = 1}) {
    final moves = legalMoves;
    if (moves.isEmpty) throw StateError('No legal Bagh Bandi moves');
    final shuffled = List<BandiMove>.from(moves)..shuffle(random);
    if (level <= 0) return shuffled.first;
    final playing = turn;

    double rate(BaghBandiGame g) {
      final state = g.outcome;
      if (state == BandiOutcome.draw) return 0;
      if (state != BandiOutcome.ongoing) {
        return (state == BandiOutcome.goats) == (playing == BandiSide.goats)
            ? 100000 : -100000;
      }
      final escapes = g.movesFor(BandiSide.tigers).length;
      final threats = g.movesFor(BandiSide.tigers)
          .where((m) => m.capture != null).length;
      final value = g.captured * 200 + escapes * 3 + threats * 22;
      return (playing == BandiSide.tigers ? value : -value).toDouble();
    }

    var best = shuffled.first;
    var bestScore = double.negativeInfinity;
    for (final candidate in shuffled) {
      final test = copy();
      test.move(candidate);
      var score = rate(test);
      if (level >= 2 && test.outcome == BandiOutcome.ongoing) {
        // Opponent chooses its strongest response, not random continuation.
        var worst = double.infinity;
        for (final answer in test.legalMoves) {
          final reply = test.copy()..move(answer);
          worst = min(worst, rate(reply));
        }
        if (worst != double.infinity) score = worst;
      }
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'goats': List<int>.from(goats),
        'tigers': tigers.toList()..sort(),
        'turn': turn.name,
        'captured': captured,
        'quietMoves': quietMoves,
      };

  factory BaghBandiGame.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) {
        throw const FormatException('Unknown Bagh Bandi save version');
      }
      final game = BaghBandiGame._(
        List<int>.from(data['goats'] as List),
        Set<int>.from(data['tigers'] as List),
        BandiSide.values.byName(data['turn'] as String),
        data['captured'] as int,
        data['quietMoves'] as int,
      );
      if (game.goats.length != 25 || game.tigers.length != 2 ||
          game.tigers.any((position) => position < 0 || position >= 25) ||
          game.captured < 0 || game.captured > 20 ||
          game.quietMoves < 0 || game.quietMoves > 100 ||
          game.goats.any((n) => n < 0 || n > 5) ||
          game.tigers.any((position) => game.goats[position] > 0) ||
          game.goatsLeft + game.captured != 20) {
        throw const FormatException('Invalid pieces or move counters');
      }
      for (var cell = 0; cell < 25; cell++) {
        if (game.goats[cell] > 1 && ![1, 3, 11, 13].contains(cell)) {
          throw const FormatException('Goats restacked illegally');
        }
      }
      return game;
    } catch (error) {
      throw FormatException('Invalid Bagh Bandi save: $error');
    }
  }
}
