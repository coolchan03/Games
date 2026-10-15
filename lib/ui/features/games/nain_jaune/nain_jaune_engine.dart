import 'dart:math';
import '../shared/playing_cards.dart';

/// Yellow Dwarf: original GPL-3.0 rules engine, 3-8 players.
class NainJauneGame {
  NainJauneGame._(this.random);
  factory NainJauneGame({int players = 4, Random? random}) {
    if (players < 3 || players > 8) {
      throw ArgumentError.value(players, 'players', 'Expected 3-8');
    }
    final g = NainJauneGame._(random ?? Random());
    g.players = players;
    g.dealer = players - 1;
    g.chips = List.filled(players, 100);
    g.trays = List.filled(5, 0);
    g._deal();
    return g;
  }

  final Random random;
  static const stakes = [1, 2, 3, 4, 5];
  static const premiumCodes = ['Td', 'Jc', 'Qs', 'Kh', '7d'];
  static const premiumNames = [
    '10 of Diamonds', 'Jack of Clubs', 'Queen of Spades',
    'King of Hearts', 'Yellow Dwarf (7 of Diamonds)',
  ];
  static const handSizes = {3: 15, 4: 12, 5: 9, 6: 8, 7: 7, 8: 6};
  late int players, dealer, current;
  int round = 1, streak = 0, playsThisRound = 0;
  int? expectedRank, lastPlayedBy, winner;
  bool roundOver = false, matchOver = false, grandOpera = false;
  late List<int> chips, trays;
  List<List<PlayingCard>> hands = [];
  final List<PlayingCard> talon = [], played = [];
  final List<String> log = [];

  static int sequenceRank(PlayingCard c) => c.rank == 14 ? 1 : c.rank;
  static int cardPenalty(PlayingCard c) => min(sequenceRank(c), 10);
  static int premiumIndex(PlayingCard c) => premiumCodes.indexOf(c.code);
  List<int> get allCardIds => [
    for (final hand in hands) ...hand.map((c) => c.id),
    ...talon.map((c) => c.id), ...played.map((c) => c.id),
  ];
  int get champion => List.generate(players, (i) => i)
      .reduce((a, b) => chips[a] >= chips[b] ? a : b);
  List<int> get legalIndices => roundOver ? const [] : [
    for (var i = 0; i < hands[current].length; i++)
      if (expectedRank == null ||
          sequenceRank(hands[current][i]) == expectedRank) i,
  ];
  bool canPlay(int i) => !roundOver && i >= 0 &&
      i < hands[current].length &&
      (expectedRank == null ||
        sequenceRank(hands[current][i]) == expectedRank);

  void _deal() {
    hands = List.generate(players, (_) => <PlayingCard>[]);
    talon.clear();
    played.clear();
    log.clear();
    expectedRank = null;
    lastPlayedBy = null;
    winner = null;
    roundOver = false;
    matchOver = false;
    grandOpera = false;
    streak = 0;
    playsThisRound = 0;
    current = (dealer + 1) % players;
    for (var seat = 0; seat < players; seat++) {
      for (var j = 0; j < stakes.length; j++) {
        chips[seat] -= stakes[j];
        trays[j] += stakes[j];
      }
    }
    final deck = CardDeck(random);
    for (var n = 0; n < handSizes[players]!; n++) {
      for (var offset = 1; offset <= players; offset++) {
        hands[(dealer + offset) % players].add(deck.draw());
      }
    }
    talon.addAll(deck.ids.map(PlayingCard.new));
    log.add('Deal $round: cards distributed; talon kept face down');
  }

  int? _nextHolder(int rank, int actor) {
    for (var offset = 0; offset < players; offset++) {
      final seat = (actor + offset) % players;
      if (hands[seat].any((c) => sequenceRank(c) == rank)) return seat;
    }
    return null;
  }

  bool play(int index) {
    if (!canPlay(index)) return false;
    final actor = current;
    final card = hands[actor].removeAt(index);
    played.add(card);
    playsThisRound++;
    streak = lastPlayedBy == actor ? streak + 1 : 1;
    lastPlayedBy = actor;
    log.add('Player ${actor + 1} plays ${card.label}');
    final premium = premiumIndex(card);
    if (premium != -1) {
      final prize = trays[premium];
      chips[actor] += prize;
      trays[premium] = 0;
      log.add('Player ${actor + 1} collects $prize from ${premiumNames[premium]}');
    }
    if (hands[actor].isEmpty) {
      _finish(actor);
    } else if (sequenceRank(card) == 13) {
      expectedRank = null;
      current = actor;
    } else {
      final next = sequenceRank(card) + 1;
      final holder = _nextHolder(next, actor);
      if (holder == null) {
        expectedRank = null;
        current = actor;
        log.add('No $next is held; Player ${actor + 1} leads again');
      } else {
        expectedRank = next;
        current = holder;
      }
    }
    return true;
  }

  void _finish(int actor) {
    winner = actor;
    roundOver = true;
    expectedRank = null;
    current = actor;
    grandOpera = streak == handSizes[players];
    for (var seat = 0; seat < players; seat++) {
      if (seat == actor) continue;
      final penalty = hands[seat].fold<int>(
          0, (sum, card) => sum + cardPenalty(card));
      final paid = min(chips[seat], penalty);
      chips[seat] -= paid;
      chips[actor] += paid;
      for (final card in hands[seat]) {
        final premium = premiumIndex(card);
        if (premium < 0) continue;
        final fine = min(chips[seat], trays[premium] * 2);
        chips[seat] -= fine;
        trays[premium] += fine;
      }
    }
    if (grandOpera) {
      for (var i = 0; i < trays.length; i++) {
        chips[actor] += trays[i];
        trays[i] = 0;
      }
    }
    matchOver = round == 5 || chips.any((amount) => amount < 15);
    log.add('Player ${actor + 1} wins deal $round'
        '${grandOpera ? ' with a Grand Opera' : ''}');
  }

  bool nextDeal() {
    if (!roundOver || matchOver) return false;
    dealer = (dealer + 1) % players;
    round++;
    _deal();
    return true;
  }

  /// Bot scores only its own hand and public trays, never opposing hands.
  int chooseBotCard(int level, Random rng) {
    final choices = legalIndices;
    if (choices.isEmpty) throw StateError('No legal cards');
    if (level <= 0) return choices[rng.nextInt(choices.length)];
    int score(int i) {
      final card = hands[current][i];
      final premium = premiumIndex(card);
      var value = premium < 0 ? 0 : trays[premium] * 3;
      if (level > 1) {
        var next = sequenceRank(card) + 1;
        while (next <= 13 &&
            hands[current].any((c) => sequenceRank(c) == next)) {
          value += 4;
          next++;
        }
        value += 14 - sequenceRank(card);
      }
      return value;
    }
    return choices.reduce((a, b) => score(a) >= score(b) ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'players': players, 'dealer': dealer, 'current': current,
    'round': round, 'streak': streak, 'playsThisRound': playsThisRound,
    'expectedRank': expectedRank, 'lastPlayedBy': lastPlayedBy,
    'winner': winner, 'roundOver': roundOver, 'matchOver': matchOver,
    'grandOpera': grandOpera,
    'chips': List<int>.from(chips), 'trays': List<int>.from(trays),
    'hands': [for (final h in hands) h.map((c) => c.id).toList()],
    'talon': talon.map((c) => c.id).toList(),
    'played': played.map((c) => c.id).toList(),
    'log': List<String>.from(log),
  };

  factory NainJauneGame.fromJson(Map<String, dynamic> json) {
    try {
      if (json['version'] != 1) throw const FormatException('Unknown version');
      final g = NainJauneGame._(Random());
      g.players = json['players'] as int;
      g.dealer = json['dealer'] as int;
      g.current = json['current'] as int;
      g.round = json['round'] as int;
      g.streak = json['streak'] as int;
      g.playsThisRound = json['playsThisRound'] as int;
      g.expectedRank = json['expectedRank'] as int?;
      g.lastPlayedBy = json['lastPlayedBy'] as int?;
      g.winner = json['winner'] as int?;
      g.roundOver = json['roundOver'] as bool;
      g.matchOver = json['matchOver'] as bool;
      g.grandOpera = json['grandOpera'] as bool;
      g.chips = List<int>.from(json['chips'] as List);
      g.trays = List<int>.from(json['trays'] as List);
      g.hands = (json['hands'] as List)
          .map((hand) => List<int>.from(hand as List)
              .map(PlayingCard.new).toList()).toList();
      g.talon.addAll(List<int>.from(json['talon'] as List).map(PlayingCard.new));
      g.played.addAll(List<int>.from(json['played'] as List).map(PlayingCard.new));
      g.log.addAll(List<String>.from(json['log'] as List));
      g._validate();
      return g;
    } catch (error) {
      throw FormatException('Invalid Yellow Dwarf save: $error');
    }
  }

  void _validate() {
    if (players < 3 || players > 8 || dealer < 0 || dealer >= players ||
        current < 0 || current >= players ||
        round < 1 || round > 5 ||
        chips.length != players || hands.length != players ||
        trays.length != 5 ||
        [...chips, ...trays].any((v) => v < 0) ||
        chips.fold<int>(0, (sum, x) => sum + x) +
            trays.fold<int>(0, (sum, x) => sum + x) != players * 100 ||
        roundOver != (winner != null) || (matchOver && !roundOver) ||
        (winner != null && (winner! < 0 || winner! >= players)) ||
        streak < 0 || streak > handSizes[players]! ||
        playsThisRound < 0 || playsThisRound > players * handSizes[players]! ||
        (expectedRank != null && (expectedRank! < 2 || expectedRank! > 13)) ||
        (lastPlayedBy != null &&
            (lastPlayedBy! < 0 || lastPlayedBy! >= players)) ||
        (roundOver && expectedRank != null) || log.length > 150) {
      throw const FormatException('Invalid Yellow Dwarf round');
    }
    final ids = allCardIds;
    if (ids.length != 52 || ids.toSet().length != 52 ||
        (!roundOver && hands.any((h) => h.isEmpty)) ||
        played.length != playsThisRound ||
        (expectedRank != null && legalIndices.isEmpty)) {
      throw const FormatException('Missing or duplicated cards');
    }
  }
}
