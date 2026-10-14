import 'dart:math';

import '../common/cards/card.dart';
import '../common/poker_eval.dart';

/// No-limit Texas Hold'em with virtual chips only. Pure Dart so it can be
/// unit tested; the screen only renders state and forwards actions.
enum Street { preflop, flop, turn, river, showdown }

enum ActionType { fold, check, call, raise }

class PokerAction {
  const PokerAction(this.type, [this.amount = 0]);
  final ActionType type;

  /// For [ActionType.raise], the total bet this street ("raise to").
  final int amount;
}

class HoldemPlayer {
  HoldemPlayer(this.name, this.chips, {this.isHuman = false});
  final String name;
  final bool isHuman;
  int chips;
  List<PlayingCard> hole = [];
  int bet = 0;
  int totalIn = 0;
  bool folded = false;
  String lastAction = '';

  bool get allIn => chips == 0 && totalIn > 0 && !folded;
  bool get inHand => !folded && hole.isNotEmpty;
  bool get canAct => inHand && chips > 0;
}

class PotResult {
  PotResult(this.amount, this.winners, this.rank);
  final int amount;
  final List<int> winners;
  final HandRank? rank;
}

class HoldemGame {
  HoldemGame({
    required List<String> names,
    int startingChips = 1000,
    this.smallBlind = 10,
    this.bigBlind = 20,
    Random? random,
  }) : rng = random ?? Random() {
    players = [
      for (var i = 0; i < names.length; i++)
        HoldemPlayer(names[i], startingChips, isHuman: i == 0),
    ];
    dealer = rng.nextInt(players.length);
  }

  final Random rng;
  final int smallBlind;
  final int bigBlind;
  late final List<HoldemPlayer> players;
  late int dealer;
  List<PlayingCard> deck = [];
  List<PlayingCard> board = [];
  Street street = Street.showdown;
  int current = 0;
  int currentBet = 0;
  int minRaise = 0;
  Set<int> toAct = {};
  List<PotResult> results = [];
  int handNumber = 0;

  int get pot => players.fold(0, (s, p) => s + p.totalIn);
  bool get handOver => street == Street.showdown;
  List<int> get seatsWithChips =>
      [for (var i = 0; i < players.length; i++) if (players[i].chips > 0) i];
  bool get matchOver => players[0].chips == 0 || seatsWithChips.length == 1;

  int _next(int from, bool Function(HoldemPlayer) ok) {
    for (var k = 1; k <= players.length; k++) {
      final i = (from + k) % players.length;
      if (ok(players[i])) return i;
    }
    return from;
  }

  void startHand() {
    if (seatsWithChips.length < 2) return;
    handNumber++;
    deck = standardDeckCards()..shuffle(rng);
    board = [];
    results = [];
    for (final p in players) {
      p.hole = [];
      p.bet = 0;
      p.totalIn = 0;
      p.folded = p.chips == 0;
      p.lastAction = p.chips == 0 ? 'Out' : '';
    }
    dealer = _next(dealer, (p) => p.chips > 0);
    for (var r = 0; r < 2; r++) {
      for (var k = 1; k <= players.length; k++) {
        final p = players[(dealer + k) % players.length];
        if (!p.folded) p.hole.add(deck.removeLast());
      }
    }
    final active = seatsWithChips.length;
    // Heads-up: the dealer posts the small blind and acts first preflop.
    final sb = active == 2 ? dealer : _next(dealer, (p) => p.chips > 0);
    final bb = _next(sb, (p) => p.chips > 0);
    _post(sb, smallBlind, 'Small blind');
    _post(bb, bigBlind, 'Big blind');
    street = Street.preflop;
    currentBet = bigBlind;
    minRaise = bigBlind;
    toAct = {for (var i = 0; i < players.length; i++) if (players[i].canAct) i};
    current = _next(bb, (p) => p.canAct);
    _settleIfNoAction();
  }

  void _post(int seat, int amount, String label) {
    final p = players[seat];
    final pay = min(amount, p.chips);
    p.chips -= pay;
    p.bet += pay;
    p.totalIn += pay;
    p.lastAction = label;
  }

  int toCall(int seat) => max(0, currentBet - players[seat].bet);

  int minRaiseTo(int seat) =>
      min(currentBet + minRaise, players[seat].bet + players[seat].chips);

  int maxRaiseTo(int seat) => players[seat].bet + players[seat].chips;

  bool canRaise(int seat) =>
      players[seat].chips > toCall(seat) &&
      players.where((p) => p.canAct).length > 1;

  void act(PokerAction action) {
    if (handOver) return;
    final seat = current;
    final p = players[seat];
    switch (action.type) {
      case ActionType.fold:
        p.folded = true;
        p.lastAction = 'Fold';
      case ActionType.check:
        if (toCall(seat) > 0) return act(const PokerAction(ActionType.call));
        p.lastAction = 'Check';
      case ActionType.call:
        final pay = min(toCall(seat), p.chips);
        p.chips -= pay;
        p.bet += pay;
        p.totalIn += pay;
        p.lastAction = pay == 0 ? 'Check' : p.chips == 0 ? 'All-in' : 'Call $pay';
      case ActionType.raise:
        final target = action.amount.clamp(minRaiseTo(seat), maxRaiseTo(seat));
        if (target <= currentBet) return act(const PokerAction(ActionType.call));
        final pay = target - p.bet;
        final raiseBy = target - currentBet;
        p.chips -= pay;
        p.bet += pay;
        p.totalIn += pay;
        // A short all-in does not reopen the minimum raise.
        if (raiseBy >= minRaise) minRaise = raiseBy;
        currentBet = target;
        p.lastAction = p.chips == 0 ? 'All-in $target' : 'Raise to $target';
        toAct = {
          for (var i = 0; i < players.length; i++)
            if (i != seat && players[i].canAct) i
        };
    }
    toAct.remove(seat);
    if (players.where((x) => x.inHand).length == 1) {
      _awardUncontested();
      return;
    }
    if (toAct.isEmpty) {
      _nextStreet();
    } else {
      current = _next(seat, (x) => toAct.contains(players.indexOf(x)));
    }
  }

  void _settleIfNoAction() {
    // Everyone (or all but one) is all-in: run out the board.
    final canAct = [for (var i = 0; i < players.length; i++) if (players[i].canAct) i];
    if (canAct.length <= 1 && canAct.every((i) => toCall(i) == 0)) {
      toAct.clear();
      _nextStreet();
    }
  }

  void _nextStreet() {
    for (final p in players) {
      p.bet = 0;
    }
    currentBet = 0;
    minRaise = bigBlind;
    switch (street) {
      case Street.preflop:
        deck.removeLast(); // burn
        board.addAll([deck.removeLast(), deck.removeLast(), deck.removeLast()]);
        street = Street.flop;
      case Street.flop:
        deck.removeLast();
        board.add(deck.removeLast());
        street = Street.turn;
      case Street.turn:
        deck.removeLast();
        board.add(deck.removeLast());
        street = Street.river;
      case Street.river:
      case Street.showdown:
        _showdown();
        return;
    }
    toAct = {for (var i = 0; i < players.length; i++) if (players[i].canAct) i};
    for (final i in toAct) {
      players[i].lastAction = '';
    }
    if (toAct.length <= 1) {
      toAct.clear();
      _nextStreet();
      return;
    }
    current = _next(dealer, (p) => p.canAct);
  }

  void _awardUncontested() {
    final winner = players.indexWhere((p) => p.inHand);
    final amount = pot;
    players[winner].chips += amount;
    results = [PotResult(amount, [winner], null)];
    for (final p in players) {
      p.totalIn = 0;
      p.bet = 0;
    }
    street = Street.showdown;
  }

  void _showdown() {
    final ranks = <int, HandRank>{
      for (var i = 0; i < players.length; i++)
        if (players[i].inHand) i: bestHand([...players[i].hole, ...board]),
    };
    results = [];
    final levels = players.map((p) => p.totalIn).where((v) => v > 0).toSet().toList()..sort();
    var prev = 0;
    for (final level in levels) {
      var amount = 0;
      for (final p in players) {
        amount += max(0, min(p.totalIn, level) - prev);
      }
      var eligible = [
        for (var i = 0; i < players.length; i++)
          if (players[i].inHand && players[i].totalIn >= level) i
      ];
      prev = level;
      if (amount == 0) continue;
      if (eligible.isEmpty) {
        // Only folded players reached this level; it goes to the deepest
        // remaining stacks so no chips disappear.
        final deepest = ranks.keys.map((i) => players[i].totalIn).reduce(max);
        eligible = [for (final i in ranks.keys) if (players[i].totalIn == deepest) i];
      }
      final best = eligible.map((i) => ranks[i]!.value).reduce(max);
      final winners = eligible.where((i) => ranks[i]!.value == best).toList();
      final share = amount ~/ winners.length;
      var odd = amount - share * winners.length;
      for (var k = 1; k <= players.length; k++) {
        final i = (dealer + k) % players.length;
        if (!winners.contains(i)) continue;
        players[i].chips += share + (odd > 0 ? 1 : 0);
        if (odd > 0) odd--;
      }
      if (results.isNotEmpty &&
          results.last.winners.toString() == winners.toString()) {
        final last = results.removeLast();
        results.add(PotResult(last.amount + amount, winners, ranks[winners.first]));
      } else {
        results.add(PotResult(amount, winners, ranks[winners.first]));
      }
    }
    for (final p in players) {
      p.totalIn = 0;
      p.bet = 0;
    }
    street = Street.showdown;
  }

  /// Monte Carlo estimate of [seat]'s chance to win against the players
  /// still in the hand, holding random cards.
  double equity(int seat, int iterations) {
    final me = players[seat];
    final opponents = players.where((p) => p.inHand && p != me).length;
    if (opponents == 0) return 1;
    final known = {...me.hole, ...board};
    final pool = standardDeckCards().where((c) => !known.contains(c)).toList();
    var score = 0.0;
    for (var it = 0; it < iterations; it++) {
      pool.shuffle(rng);
      var k = 0;
      final runout = [...board];
      while (runout.length < 5) {
        runout.add(pool[k++]);
      }
      final mine = bestHand([...me.hole, ...runout]).value;
      var beaten = false, ties = 0;
      for (var o = 0; o < opponents; o++) {
        final theirs = bestHand([pool[k++], pool[k++], ...runout]).value;
        if (theirs > mine) {
          beaten = true;
          break;
        }
        if (theirs == mine) ties++;
      }
      if (!beaten) score += 1 / (ties + 1);
    }
    return score / iterations;
  }

  /// Computer decision. [skill] 0 = easy (loose and random),
  /// 1 = medium, 2 = hard (more simulation, sizing by equity).
  PokerAction botAction(int seat, int skill) {
    final call = toCall(seat);
    final p = players[seat];
    final eq = equity(seat, [60, 220, 600][skill]);
    final potOdds = call == 0 ? 0.0 : call / (pot + call);
    final noise = (rng.nextDouble() - .5) * [0.3, 0.12, 0.05][skill];
    final strength = eq + noise;
    final opponents = players.where((x) => x.inHand && x != p).length;
    // Fair share of the pot for a coin-flip hand against these opponents.
    final par = 1 / (opponents + 1);
    final bluff = rng.nextDouble() < [0.02, 0.06, 0.08][skill];
    if (canRaise(seat) && (strength > par * 1.8 || bluff)) {
      final size = strength > par * 2.6 ? pot : (pot * .6).round();
      return PokerAction(ActionType.raise, currentBet + max(minRaise, size));
    }
    if (call == 0) return const PokerAction(ActionType.check);
    if (strength >= potOdds * (skill == 0 ? .8 : 1.05) || (call <= bigBlind && strength > par * .6)) {
      return const PokerAction(ActionType.call);
    }
    return const PokerAction(ActionType.fold);
  }
}
