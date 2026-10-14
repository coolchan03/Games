import 'dart:math';
import '../shared/playing_cards.dart';
import 'poker_evaluator.dart';

enum PokerVariant { holdem, draw }
enum PokerPhase { preflop, flop, turn, river, draw, drawBet, showdown }
enum PokerAction { fold, checkCall, raise }

/// Splits main/side pots by contribution level. Odd chips go clockwise after dealer.
List<int> distributePokerPots(List<int> contributions, List<bool> folded,
    List<int> ranks, int dealer) {
  final n = contributions.length;
  if (n < 2 || folded.length != n || ranks.length != n ||
      dealer < 0 || dealer >= n || contributions.any((x) => x < 0)) {
    throw ArgumentError('Invalid pot inputs');
  }
  final levels = contributions.where((x) => x > 0).toSet().toList()..sort();
  final awards = List<int>.filled(n, 0);
  var previous = 0;
  for (final level in levels) {
    final payers = [for (var i = 0; i < n; i++) if (contributions[i] >= level) i];
    final pot = (level - previous) * payers.length;
    previous = level;
    if (payers.length == 1) { // An uncalled excess is returned, not contested.
      awards[payers.single] += pot;
      continue;
    }
    final eligible = payers.where((i) => !folded[i]).toList();
    if (eligible.isEmpty) throw StateError('A side pot has no eligible player');
    final best = eligible.map((i) => ranks[i]).reduce(min);
    final winners = eligible.where((i) => ranks[i] == best).toList()
      ..sort((a, b) => ((a - dealer - 1 + n) % n).compareTo((b - dealer - 1 + n) % n));
    for (var i = 0; i < winners.length; i++) {
      awards[winners[i]] += pot ~/ winners.length + (i < pot % winners.length ? 1 : 0);
    }
  }
  return awards;
}

/// Original fixed-limit round controller over the licensed PHE hand evaluator.
/// Virtual chips only. Draw uses a ten-chip ante and at most three replacements.
class PokerTable {
  late PokerVariant variant;
  late PokerPhase phase;
  late int seats, dealer, current, initialChips;
  late CardDeck deck;
  late List<List<PlayingCard>> hands;
  final List<PlayingCard> community = [], discarded = [];
  late List<int> stacks, contributed, streetPaid, awards;
  late List<bool> folded;
  final Set<int> pending = {};
  final List<String> log = [];
  int currentBet = 0, raises = 0;
  bool showCards = false;
  String result = '';
  PokerTable._();
  factory PokerTable({PokerVariant variant = PokerVariant.holdem, int seats = 2,
      List<int>? startingStacks, int dealer = 0, Random? random}) {
    final amounts = startingStacks ?? List<int>.filled(seats, 200);
    if (seats < 2 || seats > 6 || amounts.length != seats ||
        amounts.any((x) => x < 0 || x > 100000) || amounts.where((x) => x > 0).length < 2 ||
        dealer < 0 || dealer >= seats) throw ArgumentError('Invalid poker table');
    final t = PokerTable._();
    t.variant = variant; t.seats = seats; t.dealer = dealer;
    t.stacks = List<int>.from(amounts);
    t.initialChips = amounts.reduce((a, b) => a + b);
    t.folded = amounts.map((x) => x == 0).toList();
    if (t.folded[t.dealer]) t.dealer = t._next(t.dealer, (i) => !t.folded[i]);
    t.current = t.dealer;
    t.contributed = List<int>.filled(seats, 0);
    t.streetPaid = List<int>.filled(seats, 0);
    t.awards = List<int>.filled(seats, 0);
    t.hands = List.generate(seats, (_) => <PlayingCard>[]);
    t.deck = CardDeck(random);
    t.phase = PokerPhase.preflop;
    for (var round = 0; round < (variant == PokerVariant.holdem ? 2 : 5); round++) {
      for (var offset = 1; offset <= seats; offset++) {
        final seat = (t.dealer + offset) % seats;
        if (!t.folded[seat]) t.hands[seat].add(t.deck.draw());
      }
    }
    if (variant == PokerVariant.holdem) {
      final small = t.alive.length == 2 ? t.dealer : t._next(t.dealer, (i) => !t.folded[i]);
      final big = t._next(small, (i) => !t.folded[i]);
      t._pay(small, 5); t._pay(big, 10); t.currentBet = 10;
      t.current = big;
    } else {
      for (final seat in t.alive) { t._pay(seat, 10); }
      t.streetPaid.fillRange(0, seats, 0);
    }
    t.pending.addAll(t.alive.where((i) => t.stacks[i] > 0));
    t._advance();
    return t;
  }
  bool get ended => phase == PokerPhase.showdown;
  List<int> get alive => [for (var i = 0; i < seats; i++) if (!folded[i]) i];
  int get pot => contributed.fold(0, (a, b) => a + b);
  int get betSize => phase == PokerPhase.turn || phase == PokerPhase.river || phase == PokerPhase.drawBet ? 20 : 10;
  int get toCall => max(0, currentBet - streetPaid[current]);
  bool get canRaise => !ended && phase != PokerPhase.draw && raises < 3 &&
    stacks[current] >= toCall + betSize && alive.any((i) => i != current && stacks[i] > 0);
  String get phaseLabel => switch (phase) {
    PokerPhase.preflop => variant == PokerVariant.holdem ? 'Pre-flop' : 'Opening bets',
    PokerPhase.flop => 'Flop', PokerPhase.turn => 'Turn', PokerPhase.river => 'River',
    PokerPhase.draw => 'Draw up to three cards', PokerPhase.drawBet => 'Final bets',
    PokerPhase.showdown => 'Hand complete',
  };
  int _next(int from, bool Function(int) eligible) {
    for (var offset = 1; offset <= seats; offset++) {
      final seat = (from + offset) % seats;
      if (eligible(seat)) return seat;
    }
    throw StateError('No eligible player');
  }
  void _pay(int seat, int amount) {
    final paid = min(stacks[seat], amount);
    stacks[seat] -= paid; contributed[seat] += paid; streetPaid[seat] += paid;
  }
  bool act(PokerAction action) {
    if (ended || phase == PokerPhase.draw || !pending.contains(current)) return false;
    final player = current;
    if (action == PokerAction.raise && !canRaise) return false;
    if (action == PokerAction.fold) {
      folded[player] = true; log.add('Player ${player + 1} folds');
    } else if (action == PokerAction.checkCall) {
      final amount = min(stacks[player], toCall);
      _pay(player, amount);
      log.add('Player ${player + 1} ${amount == 0 ? 'checks' : 'calls $amount'}');
    } else {
      final amount = toCall + betSize;
      currentBet += betSize; raises++;
      _pay(player, amount);
      pending.addAll(alive.where((i) => stacks[i] > 0));
      log.add('Player ${player + 1} raises to $currentBet');
    }
    pending.remove(player);
    _advance();
    return true;
  }
  bool replaceCards(Set<int> indices) {
    if (phase != PokerPhase.draw || !pending.contains(current) || indices.length > 3 ||
        indices.any((i) => i < 0 || i >= 5)) return false;
    for (final i in indices.toList()..sort()) {
      discarded.add(hands[current][i]); hands[current][i] = deck.draw();
    }
    log.add('Player ${current + 1} draws ${indices.length}');
    pending.remove(current);
    _advance();
    return true;
  }
  void _advance() {
    if (alive.length == 1) {
      awards[alive.single] = pot;
      stacks[alive.single] += pot;
      result = 'Player ${alive.single + 1} wins $pot chips; others folded';
      phase = PokerPhase.showdown; pending.clear(); return;
    }
    pending.removeWhere((i) => folded[i] || (phase != PokerPhase.draw && stacks[i] == 0));
    if (phase != PokerPhase.draw) {
      final funded = alive.where((i) => stacks[i] > 0).toList();
      if (funded.length == 1) {
        // No opponent can match a further bet. Short blinds need only be
        // matched to their actual payment, not the nominal big blind.
        currentBet = alive.where((i) => i != funded.single)
          .map((i) => streetPaid[i]).fold<int>(0, max);
      }
      if (funded.length < 2 && pending.every((i) => streetPaid[i] >= currentBet)) {
        pending.clear();
      }
    }
    if (pending.isNotEmpty) { current = _next(current, pending.contains); return; }
    _nextPhase();
  }
  void _nextPhase() {
    if (phase == PokerPhase.river || phase == PokerPhase.drawBet) { _showdown(); return; }
    if (variant == PokerVariant.draw) {
      phase = phase == PokerPhase.preflop ? PokerPhase.draw : PokerPhase.drawBet;
    } else {
      phase = switch (phase) {
        PokerPhase.preflop => PokerPhase.flop,
        PokerPhase.flop => PokerPhase.turn,
        _ => PokerPhase.river,
      };
      discarded.add(deck.draw()); // Burn before each community street.
      for (var i = 0; i < (phase == PokerPhase.flop ? 3 : 1); i++) { community.add(deck.draw()); }
    }
    streetPaid.fillRange(0, seats, 0); currentBet = 0; raises = 0;
    pending.addAll(alive.where((i) => phase == PokerPhase.draw || stacks[i] > 0));
    current = dealer;
    _advance();
  }
  void _showdown() {
    final ranks = [for (var i = 0; i < seats; i++)
      folded[i] ? 9999 : evaluatePoker([...hands[i], ...community]).value];
    awards = distributePokerPots(contributed, folded, ranks, dealer);
    for (var i = 0; i < seats; i++) { stacks[i] += awards[i]; }
    result = [for (var i = 0; i < seats; i++) if (awards[i] > 0)
      'Player ${i + 1}: ${awards[i]} chips'].join(' | ');
    showCards = true; phase = PokerPhase.showdown; pending.clear();
  }
  PokerTable nextHand([Random? random]) {
    if (!ended || stacks.where((x) => x > 0).length < 2) throw StateError('Start a new table');
    return PokerTable(variant: variant, seats: seats, startingStacks: stacks,
      dealer: _next(dealer, (i) => stacks[i] > 0), random: random);
  }
  Map<String, dynamic> toJson() => {
    'version': 1, 'variant': variant.name, 'phase': phase.name, 'seats': seats,
    'dealer': dealer, 'current': current, 'initialChips': initialChips,
    'deck': deck.ids, 'hands': hands.map((h) => h.map((c) => c.id).toList()).toList(),
    'community': community.map((c) => c.id).toList(), 'discarded': discarded.map((c) => c.id).toList(),
    'stacks': List<int>.from(stacks), 'contributed': List<int>.from(contributed),
    'streetPaid': List<int>.from(streetPaid), 'awards': List<int>.from(awards),
    'folded': List<bool>.from(folded), 'pending': pending.toList(),
    'currentBet': currentBet, 'raises': raises, 'showCards': showCards, 'result': result,
    'log': List<String>.from(log),
  };
  factory PokerTable.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) throw const FormatException('Unsupported poker save');
      final t = PokerTable._();
      t.variant = PokerVariant.values.byName(data['variant'] as String);
      t.phase = PokerPhase.values.byName(data['phase'] as String);
      t.seats = data['seats'] as int; t.dealer = data['dealer'] as int;
      t.current = data['current'] as int; t.initialChips = data['initialChips'] as int;
      List<int> ints(String key) => List<int>.from(data[key] as List);
      t.deck = CardDeck.restore(ints('deck'));
      t.hands = (data['hands'] as List).map((h) => List<int>.from(h as List).map(PlayingCard.new).toList()).toList();
      t.community.addAll(ints('community').map(PlayingCard.new));
      t.discarded.addAll(ints('discarded').map(PlayingCard.new));
      t.stacks = ints('stacks'); t.contributed = ints('contributed');
      t.streetPaid = ints('streetPaid'); t.awards = ints('awards');
      t.folded = List<bool>.from(data['folded'] as List); t.pending.addAll(ints('pending'));
      t.currentBet = data['currentBet'] as int; t.raises = data['raises'] as int;
      t.showCards = data['showCards'] as bool; t.result = data['result'] as String;
      t.log.addAll(List<String>.from(data['log'] as List));
      t._validate();
      return t;
    } catch (error) { throw FormatException('Invalid poker save: $error'); }
  }
  void _validate() {
    if (seats < 2 || seats > 6 || dealer < 0 || dealer >= seats || current < 0 || current >= seats ||
        [hands.length, stacks.length, contributed.length, streetPaid.length, awards.length, folded.length].any((n) => n != seats) ||
        [...stacks, ...contributed, ...streetPaid, ...awards].any((n) => n < 0) ||
        initialChips <= 0 || initialChips > 600000 || currentBet < 0 || raises < 0 || raises > 3 ||
        log.length > 200 || pending.any((i) => i < 0 || i >= seats || folded[i]) ||
        (!ended && (!pending.contains(current) || pending.isEmpty))) throw const FormatException('Invalid round state');
    final cards = [...deck.ids, ...hands.expand((h) => h.map((c) => c.id)),
      ...community.map((c) => c.id), ...discarded.map((c) => c.id)];
    if (cards.length != 52 || cards.toSet().length != 52) throw const FormatException('Cards are duplicated or missing');
    if (stacks.fold<int>(0, (a, b) => a + b) + (ended ? 0 : pot) != initialChips) {
      throw const FormatException('Chip conservation failed');
    }
    for (var i = 0; i < seats; i++) {
      if (streetPaid[i] > contributed[i] || (!folded[i] && hands[i].length != (variant == PokerVariant.holdem ? 2 : 5))) {
        throw const FormatException('Invalid player state');
      }
    }
    if (ended && pending.isNotEmpty) throw const FormatException('Completed hand has pending actions');
    if (!ended && showCards) throw const FormatException('Private cards revealed in active hand');
    if (variant == PokerVariant.draw) {
      if (community.isNotEmpty || ![PokerPhase.preflop, PokerPhase.draw, PokerPhase.drawBet, PokerPhase.showdown].contains(phase)) {
        throw const FormatException('Invalid draw phase');
      }
    } else {
      final expected = {PokerPhase.preflop: 0, PokerPhase.flop: 3, PokerPhase.turn: 4, PokerPhase.river: 5};
      if ((!ended && expected[phase] != community.length) ||
          (ended && ![0, 3, 4, 5].contains(community.length)) ||
          (showCards && community.length != 5)) throw const FormatException('Invalid board for betting phase');
    }
  }
}

/// Uses only the acting seat's cards and public community cards, never opponents.
PokerAction pokerBotAction(PokerTable table, Random random) {
  final cards = [...table.hands[table.current], ...table.community];
  final strength = cards.length >= 5 ? 1 - evaluatePoker(cards).value / 7462
    : (cards[0].rank == cards[1].rank ? 0.7 : (cards[0].rank + cards[1].rank) / 40);
  if (table.canRaise && (strength > 0.65 || random.nextDouble() < 0.08)) return PokerAction.raise;
  if (table.toCall > 0 && strength < 0.3 && random.nextDouble() < 0.55) return PokerAction.fold;
  return PokerAction.checkCall;
}
Set<int> pokerBotDiscards(List<PlayingCard> hand) {
  if (evaluatePoker(hand).value <= 1609) return {};
  final counts = <int, int>{};
  for (final card in hand) { counts.update(card.rank, (n) => n + 1, ifAbsent: () => 1); }
  final choices = [for (var i = 0; i < hand.length; i++) if (counts[hand[i].rank] == 1) i]
    ..sort((a, b) => hand[a].rank.compareTo(hand[b].rank));
  return choices.take(3).toSet();
}
