import 'dart:math';

/// A three-die French 421 hand; the order of the dice is irrelevant.
/// Original Dart rules implementation, under the application's GPL-3.0.
class Dice421Hand {
  Dice421Hand(List<int> values) : dice = List<int>.of(values) {
    if (dice.length != 3 || dice.any((n) => n < 1 || n > 6)) {
      throw ArgumentError.value(values, 'dice', 'Three values from 1 to 6 required');
    }
  }

  final List<int> dice;
  List<int> get sorted => List<int>.of(dice)..sort((a, b) => b.compareTo(a));
  bool get is421 => sorted.join() == '421';
  bool get isTriple => sorted[0] == sorted[2];
  bool get isFiche => sorted[1] == 1 && sorted[2] == 1 && sorted[0] > 1;
  bool get isRun => sorted[0] == sorted[1] + 1 &&
      sorted[1] == sorted[2] + 1;

  int get strength {
    final s = sorted;
    if (is421) return 100000;
    if (isTriple && s.first == 1) return 99000;
    if (isFiche) return 98000 + s.first * 2;
    if (isTriple) return 98000 + s.first * 2 - 1;
    if (isRun) return 97000 + s.first;
    return 1000 + s[0] * 100 + s[1] * 10 + s[2];
  }

  int get chips {
    if (is421) return 10;
    if (isTriple && sorted.first == 1) return 7;
    if (isFiche || isTriple) return sorted.first;
    if (isRun || sorted.join() == '221') return 2;
    return 1;
  }

  String get label => sorted.join(' - ');
}

enum Dice421Phase { charge, discharge, finished }

/// Three-dice 421 with a 21-counter bank, charge then discharge.
/// Charge: one throw per seat. Discharge: up to 3 throws, first seat sets limit.
class Dice421Game {
  Dice421Game({this.players = 2, this.computer = false, Random? random})
      : rng = random ?? Random() {
    if (players < 2 || players > 4 || (computer && players != 2)) {
      throw ArgumentError('421 requires 2-4 local players or a two-seat bot game');
    }
    tokens = List<int>.filled(players, 0);
    results = List<List<int>?>.filled(players, null);
  }

  Dice421Game._(this.players, this.computer, this.rng);

  final int players;
  final bool computer;
  final Random rng;
  Dice421Phase phase = Dice421Phase.charge;
  int bank = 21;
  late List<int> tokens;
  int current = 0;
  int throwsTaken = 0;
  int roundRollLimit = 3;
  int rounds = 0;
  List<int> dice = [0, 0, 0];
  List<bool> held = [false, false, false];
  late List<List<int>?> results;
  int? winner;
  String message = 'Charge: one throw per player; lowest hand takes counters.';

  int get allowedThrows => phase == Dice421Phase.charge
      ? 1
      : current == 0 ? 3 : roundRollLimit;

  bool roll() {
    if (phase == Dice421Phase.finished || throwsTaken >= allowedThrows) {
      return false;
    }
    for (var i = 0; i < 3; i++) {
      if (throwsTaken == 0 || !held[i]) dice[i] = rng.nextInt(6) + 1;
    }
    throwsTaken++;
    return true;
  }

  bool toggleHeld(int index) {
    if (phase != Dice421Phase.discharge || throwsTaken == 0 ||
        throwsTaken >= allowedThrows || index < 0 || index >= 3) {
      return false;
    }
    held[index] = !held[index];
    return true;
  }

  bool stand() {
    if (throwsTaken == 0 || phase == Dice421Phase.finished) return false;
    results[current] = List<int>.of(dice);
    if (current == 0 && phase == Dice421Phase.discharge) {
      roundRollLimit = throwsTaken;
    }
    if (current < players - 1) {
      current++;
      _clearDice();
    } else {
      final played = results.map((r) => r!).toList();
      resolveRound(played);
    }
    return true;
  }

  void _clearDice() {
    throwsTaken = 0;
    dice = [0, 0, 0];
    held = [false, false, false];
  }

  /// Resolve a complete round; exposed for deterministic rules testing.
  void resolveRound(List<List<int>> rolls) {
    if (phase == Dice421Phase.finished || rolls.length != players) {
      throw StateError('Not a complete active 421 round');
    }
    final hands = rolls.map(Dice421Hand.new).toList();
    final best = hands.map((h) => h.strength).reduce(max);
    final worst = hands.map((h) => h.strength).reduce(min);
    final strongest = [for (var i = 0; i < players; i++)
      if (hands[i].strength == best) i];
    final weakest = [for (var i = 0; i < players; i++)
      if (hands[i].strength == worst) i];
    if (strongest.length != 1 || weakest.length != 1 ||
        strongest.single == weakest.single) {
      message = 'Equal hands: replay the round; no counters exchanged.';
    } else {
      final a = strongest.single, b = weakest.single;
      final value = hands[b].sorted.join() == '221'
          ? 2 : hands[a].chips;
      if (phase == Dice421Phase.charge) {
        final moved = min(bank, value);
        bank -= moved;
        tokens[b] += moved;
        message = 'Player ${b + 1} receives $moved counters from the bank.';
        if (bank == 0) {
          phase = Dice421Phase.discharge;
          message += ' Charge ended: discharge begins.';
        }
      } else {
        final moved = min(tokens[a], value);
        tokens[a] -= moved;
        tokens[b] += moved;
        message = 'Player ${a + 1} gives $moved counters to Player ${b + 1}.';
        if (tokens[a] == 0) {
          winner = a;
          phase = Dice421Phase.finished;
          message += ' Player ${a + 1} wins!';
        }
      }
    }
    rounds++;
    current = 0;
    roundRollLimit = 3;
    results = List<List<int>?>.filled(players, null);
    _clearDice();
  }

  bool playComputerTurn() {
    if (!computer || current != 1 || phase == Dice421Phase.finished ||
        throwsTaken != 0) return false;
    roll();
    if (phase == Dice421Phase.discharge) {
      if (Dice421Hand(dice).strength < 97000 && allowedThrows > 1) {
        for (var i = 0; i < 3; i++) {
          // Keep pairs and promising faces while searching for 421.
          held[i] = dice[i] == 1 || dice[i] == 4 || dice[i] == 2;
        }
        roll();
      }
      if (Dice421Hand(dice).strength < 97000 && throwsTaken < allowedThrows) {
        roll();
      }
    }
    return stand();
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'players': players, 'computer': computer,
    'phase': phase.name, 'bank': bank, 'tokens': List<int>.of(tokens),
    'current': current, 'throwsTaken': throwsTaken,
    'roundRollLimit': roundRollLimit, 'rounds': rounds,
    'dice': List<int>.of(dice), 'held': List<bool>.of(held),
    'results': [for (final hand in results)
      if (hand == null) null else List<int>.of(hand)],
    'winner': winner, 'message': message,
  };

  factory Dice421Game.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) {
        throw const FormatException('Unknown 421 save version');
      }
      final players = data['players'] as int;
      final computer = data['computer'] as bool;
      final game = Dice421Game._(players, computer, Random());
      game.phase = Dice421Phase.values.byName(data['phase'] as String);
      game.bank = data['bank'] as int;
      game.tokens = List<int>.from(data['tokens'] as List);
      game.current = data['current'] as int;
      game.throwsTaken = data['throwsTaken'] as int;
      game.roundRollLimit = data['roundRollLimit'] as int;
      game.rounds = data['rounds'] as int;
      game.dice = List<int>.from(data['dice'] as List);
      game.held = List<bool>.from(data['held'] as List);
      game.results = (data['results'] as List).map<List<int>?>((value) =>
        value == null ? null : List<int>.from(value as List)).toList();
      game.winner = data['winner'] as int?;
      game.message = data['message'] as String;
      game._validate();
      return game;
    } catch (error) {
      throw FormatException('Invalid 421 save: $error');
    }
  }

  void _validate() {
    if (players < 2 || players > 4 || (computer && players != 2) ||
        bank < 0 || bank > 21 || tokens.length != players ||
        tokens.any((value) => value < 0 || value > 21) ||
        bank + tokens.fold<int>(0, (sum, value) => sum + value) != 21 ||
        current < 0 || current >= players || rounds < 0 ||
        roundRollLimit < 1 || roundRollLimit > 3 ||
        throwsTaken < 0 || throwsTaken > allowedThrows ||
        dice.length != 3 || held.length != 3 || results.length != players ||
        (throwsTaken == 0 && (dice.any((n) => n != 0) || held.contains(true))) ||
        (throwsTaken > 0 && dice.any((n) => n < 1 || n > 6)) ||
        (phase == Dice421Phase.charge && bank == 0) ||
        (phase != Dice421Phase.charge && bank != 0) ||
        (phase == Dice421Phase.finished) != (winner != null) ||
        (winner != null && (winner! < 0 || winner! >= players ||
          tokens[winner!] != 0))) {
      throw const FormatException('Inconsistent counter/turn state');
    }
    for (final result in results) {
      if (result != null &&
          (result.length != 3 || result.any((n) => n < 1 || n > 6))) {
        throw const FormatException('Invalid completed roll');
      }
    }
  }
}
