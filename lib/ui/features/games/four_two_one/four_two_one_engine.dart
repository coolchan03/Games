import 'dart:math';

/// French 421, the 21-token charge/discharge house variant.
/// Ordering and chip values follow the two-aces, triples, runs, points table.
/// Tied best or worst hands replay rather than giving ties a seat advantage.
class FourTwoOneHand {
  FourTwoOneHand(List<int> dice) : dice = List<int>.unmodifiable(dice) {
    if (dice.length != 3 || dice.any((d) => d < 1 || d > 6)) {
      throw ArgumentError.value(dice, 'dice', 'Three six-sided dice required');
    }
  }
  final List<int> dice;
  List<int> get sorted => List<int>.from(dice)..sort((a, b) => b.compareTo(a));
  int get strength {
    final d = sorted;
    if (d[0] == 4 && d[1] == 2 && d[2] == 1) return 900000;
    if (d[0] == 1 && d[1] == 1) return 800000;
    if (d[1] == 1 && d[2] == 1 && d[0] > 1) return 700000 + d[0] * 2;
    if (d[0] == d[1] && d[1] == d[2]) return 700000 + d[0] * 2 - 1;
    if (d[0] == d[1] + 1 && d[1] == d[2] + 1) return 600000 + d[0];
    if (d[0] == 2 && d[1] == 2 && d[2] == 1) return 0;
    return 100000 + d[0] * 100 + d[1] * 10 + d[2];
  }
  int get chips {
    final d = sorted;
    if (strength == 900000) return 10;
    if (d[1] == 1 && d[2] == 1 && d[0] > 1) return d[0];
    if (d[0] == 1 && d[1] == 1) return 7;
    if (d[0] == d[1] && d[1] == d[2]) return d[0];
    if (strength >= 600000 && strength < 700000) return 2;
    return 1;
  }
  String get label => sorted.join('-');
}

enum FourTwoOnePhase { charge, discharge, finished }

class FourTwoOneGame {
  FourTwoOneGame({this.players = 2, Random? random})
      : rng = random ?? Random(), chips = List<int>.filled(players, 0),
        hands = List<List<int>?>.filled(players, null) {
    if (players < 2 || players > 6) {
      throw ArgumentError.value(players, 'players', 'Expected 2-6 players');
    }
    _beginRound();
  }
  FourTwoOneGame._(this.players) : rng = Random(),
      chips = List<int>.filled(players, 0),
      hands = List<List<int>?>.filled(players, null);
  final int players;
  final Random rng;
  List<int> chips;
  List<List<int>?> hands;
  FourTwoOnePhase phase = FourTwoOnePhase.charge;
  int bank = 21, leader = 0, position = 0, roundNumber = 1;
  int rollsUsed = 0, rollLimit = 3;
  int? loserSeat;
  List<int> order = [], dice = [];
  final Set<int> held = {};
  String message = 'Charge: avoid taking chips from the bank';
  int get current => order[position];
  bool get finished => phase == FourTwoOnePhase.finished;

  void _beginRound() {
    final active = [for (var i = 0; i < players; i++)
      if (phase == FourTwoOnePhase.charge || chips[i] > 0) i];
    if (active.length < 2) {
      phase = FourTwoOnePhase.finished;
      loserSeat = active.isEmpty ? null : active.single;
      return;
    }
    final start = active.contains(leader) ? leader : active.first;
    final idx = active.indexOf(start);
    order = [...active.skip(idx), ...active.take(idx)];
    hands = List<List<int>?>.filled(players, null);
    position = 0;
    _clearTurn();
    rollLimit = 3;
  }

  void _clearTurn() {
    dice = [];
    held.clear();
    rollsUsed = 0;
  }

  bool roll({List<int>? fixed}) {
    if (fixed != null &&
        (fixed.length != 3 || fixed.any((d) => d < 1 || d > 6))) {
      throw ArgumentError.value(fixed, 'fixed', 'Three valid dice required');
    }
    if (finished || rollsUsed >= rollLimit) return false;
    if (dice.isEmpty) dice = [1, 1, 1];
    final fresh = fixed ?? [for (var i = 0; i < 3; i++) rng.nextInt(6) + 1];
    for (var i = 0; i < 3; i++) {
      if (rollsUsed == 0 || !held.contains(i)) dice[i] = fresh[i];
    }
    rollsUsed++;
    return true;
  }

  bool hold(int index) {
    if (index < 0 || index >= 3 || finished ||
        rollsUsed == 0 || rollsUsed >= rollLimit) return false;
    if (!held.add(index)) held.remove(index);
    return true;
  }

  bool stop() {
    if (finished || rollsUsed == 0) return false;
    final seat = current;
    hands[seat] = List<int>.from(dice);
    if (position == 0) rollLimit = rollsUsed;
    if (position + 1 < order.length) {
      position++;
      _clearTurn();
      return true;
    }
    _settle();
    return true;
  }

  void _settle() {
    final scores = {for (final i in order) i: FourTwoOneHand(hands[i]!).strength};
    final targetScore = scores.values.reduce(min);
    final seats = [for (final i in order) if (scores[i] == targetScore) i];
    if (seats.length == 1) {
      final target = seats.single;
      final high = [for (final i in order) FourTwoOneHand(hands[i]!).strength]
          .reduce(max);
      final winner = order.firstWhere((i) => scores[i] == high);
      final award = FourTwoOneHand(hands[winner]!).chips;
      final amount = phase == FourTwoOnePhase.charge
          ? min(award, bank) : min(award, chips[winner]);
      if (phase == FourTwoOnePhase.charge) {
        bank -= amount;
        chips[target] += amount;
        message = 'Player ${target + 1} takes $amount chips';
        if (bank == 0) {
          phase = FourTwoOnePhase.discharge;
          message += '. Discharge begins';
        }
      } else {
        chips[winner] -= amount;
        chips[target] += amount;
        message = 'Player ${winner + 1} passes $amount chips to player ${target + 1}';
      }
      leader = target;
    } else {
      message = 'Tied hands — replay this round';
    }
    roundNumber++;
    _beginRound();
  }

  bool autoTurn() {
    if (finished || rollsUsed > 0) return false;
    for (var attempt = 0; attempt < rollLimit; attempt++) {
      roll();
      if (FourTwoOneHand(dice).strength >= 700000) break;
    }
    return stop();
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'players': players, 'phase': phase.name,
    'bank': bank, 'chips': List<int>.from(chips),
    'hands': [for (final hand in hands) hand == null ? null : List<int>.from(hand)],
    'leader': leader, 'position': position, 'roundNumber': roundNumber,
    'rollsUsed': rollsUsed, 'rollLimit': rollLimit,
    'dice': List<int>.from(dice), 'held': held.toList()..sort(),
    'order': List<int>.from(order), 'loser': loserSeat, 'message': message,
  };

  factory FourTwoOneGame.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) throw const FormatException('Unsupported save');
      final n = data['players'] as int;
      if (n < 2 || n > 6) throw const FormatException('Invalid player count');
      final g = FourTwoOneGame._(n);
      g.phase = FourTwoOnePhase.values.byName(data['phase'] as String);
      g.bank = data['bank'] as int;
      g.chips = List<int>.from(data['chips'] as List);
      g.hands = [for (final h in data['hands'] as List)
        h == null ? null : List<int>.from(h as List)];
      g.leader = data['leader'] as int;
      g.position = data['position'] as int;
      g.roundNumber = data['roundNumber'] as int;
      g.rollsUsed = data['rollsUsed'] as int;
      g.rollLimit = data['rollLimit'] as int;
      g.dice = List<int>.from(data['dice'] as List);
      g.held.addAll(List<int>.from(data['held'] as List));
      g.order = List<int>.from(data['order'] as List);
      g.loserSeat = data['loser'] as int?;
      g.message = data['message'] as String;
      g._validate();
      return g;
    } catch (error) {
      throw FormatException('Invalid 421 save: $error');
    }
  }

  void _validate() {
    if (chips.length != players || hands.length != players ||
        bank < 0 || chips.any((n) => n < 0 || n > 21) ||
        chips.fold<int>(bank, (total, n) => total + n) != 21 ||
        leader < 0 || leader >= players || roundNumber < 1 ||
        order.toSet().length != order.length ||
        order.any((i) => i < 0 || i >= players) ||
        position < 0 || (order.isNotEmpty && position >= order.length) ||
        rollsUsed < 0 || rollsUsed > rollLimit || rollLimit < 1 || rollLimit > 3 ||
        dice.length != (rollsUsed == 0 ? 0 : 3) ||
        dice.any((n) => n < 1 || n > 6) ||
        held.any((n) => n < 0 || n >= 3) ||
        hands.any((h) => h != null &&
            (h.length != 3 || h.any((d) => d < 1 || d > 6))) ||
        (phase == FourTwoOnePhase.charge && bank == 0)) {
      throw const FormatException('Invalid round, dice or token conservation');
    }
    if (!finished && (order.length < 2 ||
        order.any((seat) => phase == FourTwoOnePhase.discharge && chips[seat] == 0) ||
        hands[current] != null)) {
      throw const FormatException('Invalid current player');
    }
    if (finished && (loserSeat == null && chips.where((n) => n > 0).isNotEmpty)) {
      throw const FormatException('Invalid final outcome');
    }
  }
}
