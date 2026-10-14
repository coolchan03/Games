import 'dart:math';
import '../shared/playing_cards.dart';

/// Kings in the Corner: original GPL-3.0 Dart rules controller.
////// Variant: draw at the start, build down in alternating colors, single round.
/// Eight tableau positions: 0-3 are sides, 4-7 are king-only corners.
class KingsCornerGame {
  late int players, dealer, current, consecutivePasses;
  late bool finished, turnMadeMove;
  late int? winner;
  late CardDeck stock;
  late List<List<PlayingCard>> hands, piles;

  KingsCornerGame._();

  factory KingsCornerGame({int players = 2, Random? random}) {
    if (players < 2 || players > 4) {
      throw ArgumentError.value(players, 'players', 'Expected 2-4 players');
    }
    final game = KingsCornerGame._();
    game.players = players;
    game.dealer = players - 1;
    game.current = 0;
    game.finished = false;
    game.turnMadeMove = false;
    game.winner = null;
    game.consecutivePasses = 0;
    game.stock = CardDeck(random);
    game.hands = List.generate(players, (_) => <PlayingCard>[]);
    game.piles = List.generate(8, (_) => <PlayingCard>[]);
    for (var index = 0; index < 7; index++) {
      for (var seat = 0; seat < players; seat++) {
        game.hands[seat].add(game.stock.draw());
      }
    }
    for (var side = 0; side < 4; side++) {
      game.piles[side].add(game.stock.draw());
    }
    // Drawing once at the beginning of every turn is the documented variant.
    game.hands[game.current].add(game.stock.draw());
    return game;
  }

  List<int> get allCardIds => [
        ...stock.ids,
        for (final hand in hands) ...hand.map((card) => card.id),
        for (final pile in piles) ...pile.map((card) => card.id),
      ];

  List<int> get penaltyScores => [
        for (final hand in hands)
          hand.fold<int>(0, (sum, card) => sum + (card.rank == 13 ? 10 : 1)),
      ];

  static int _buildRank(PlayingCard card) => card.rank == 14 ? 1 : card.rank;
  static bool _red(PlayingCard card) => card.suit == 1 || card.suit == 2;

  static bool canBuild(PlayingCard card, PlayingCard onto) =>
      _buildRank(card) + 1 == _buildRank(onto) && _red(card) != _red(onto);

  bool canPlayCard(int handIndex, int pileIndex) {
    if (finished || handIndex < 0 || handIndex >= hands[current].length ||
        pileIndex < 0 || pileIndex >= piles.length) return false;
    final card = hands[current][handIndex];
    final pile = piles[pileIndex];
    if (pile.isEmpty) return pileIndex < 4 || card.rank == 13;
    return canBuild(card, pile.last);
  }

  bool playCard(int handIndex, int pileIndex) {
    if (!canPlayCard(handIndex, pileIndex)) return false;
    piles[pileIndex].add(hands[current].removeAt(handIndex));
    turnMadeMove = true;
    consecutivePasses = 0;
    if (hands[current].isEmpty) {
      finished = true;
      winner = current;
    }
    return true;
  }

  /// Side stacks may merge onto another stack or move a king into a corner.
  bool canMovePile(int from, int to) {
    if (finished || from < 0 || from >= 4 || to < 0 || to >= 8 ||
        from == to || piles[from].isEmpty) return false;
    final target = piles[to];
    if (target.isEmpty) return to >= 4 && piles[from].first.rank == 13;
    return canBuild(piles[from].first, target.last);
  }

  bool movePile(int from, int to) {
    if (!canMovePile(from, to)) return false;
    piles[to].addAll(piles[from]);
    piles[from].clear();
    turnMadeMove = true;
    consecutivePasses = 0;
    return true;
  }

  bool endTurn() {
    if (finished) return false;
    consecutivePasses = turnMadeMove ? 0 : consecutivePasses + 1;
    turnMadeMove = false;
    if (stock.remaining == 0 && consecutivePasses >= players) {
      final penalties = penaltyScores;
      final best = penalties.reduce(min);
      winner = penalties.indexOf(best);
      finished = true;
      return true;
    }
    current = (current + 1) % players;
    if (stock.remaining > 0) hands[current].add(stock.draw());
    return true;
  }

  /// Casual bot: consults only its own hand and the public tableau.
  /// Each successful merger reduces piles; drawing cannot occur mid-turn.
  bool playGreedyTurn() {
    if (finished) return false;
    for (var moves = 0; moves < 52 && !finished; moves++) {
      var acted = false;
      for (var handIndex = 0; handIndex < hands[current].length && !acted; handIndex++) {
        for (var pileIndex = 0; pileIndex < 8; pileIndex++) {
          if (playCard(handIndex, pileIndex)) {
            acted = true;
            break;
          }
        }
      }
      if (!acted) {
        for (var from = 0; from < 4 && !acted; from++) {
          for (var to = 0; to < 8; to++) {
            if (movePile(from, to)) {
              acted = true;
              break;
            }
          }
        }
      }
      if (!acted) break;
    }
    if (!finished) endTurn();
    return true;
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'players': players,
        'dealer': dealer,
        'current': current,
        'passes': consecutivePasses,
        'moved': turnMadeMove,
        'finished': finished,
        'winner': winner,
        'stock': stock.ids,
        'hands': [for (final hand in hands) hand.map((card) => card.id).toList()],
        'piles': [for (final pile in piles) pile.map((card) => card.id).toList()],
      };

  factory KingsCornerGame.fromJson(Map<String, dynamic> data) {
    try {
      if (data['version'] != 1) throw const FormatException('Unknown save version');
      final game = KingsCornerGame._();
      game.players = data['players'] as int;
      game.dealer = data['dealer'] as int;
      game.current = data['current'] as int;
      game.consecutivePasses = data['passes'] as int;
      game.turnMadeMove = data['moved'] as bool;
      game.finished = data['finished'] as bool;
      game.winner = data['winner'] as int?;
      game.stock = CardDeck.restore(List<int>.from(data['stock'] as List));
      List<List<PlayingCard>> decode(String key) {
        return (data[key] as List)
            .map((row) => List<int>.from(row as List)
                .map(PlayingCard.new).toList())
            .toList();
      }
      game.hands = decode('hands');
      game.piles = decode('piles');
      game._validate();
      return game;
    } catch (error) {
      throw FormatException('Invalid Kings Corner save: $error');
    }
  }

  void _validate() {
    if (players < 2 || players > 4 || dealer < 0 || dealer >= players ||
        current < 0 || current >= players || hands.length != players ||
        piles.length != 8 || consecutivePasses < 0 || consecutivePasses > players ||
        finished != (winner != null) ||
        (winner != null && (winner! < 0 || winner! >= players))) {
      throw const FormatException('Invalid turn or winner');
    }
    final ids = allCardIds;
    if (ids.length != 52 || ids.toSet().length != 52 ||
        (!finished && hands.any((hand) => hand.isEmpty))) {
      throw const FormatException('Missing, duplicated or misplaced cards');
    }
    for (var i = 0; i < piles.length; i++) {
      final pile = piles[i];
      if (i >= 4 && pile.isNotEmpty && pile.first.rank != 13) {
        throw const FormatException('Corner without a king');
      }
      for (var j = 1; j < pile.length; j++) {
        if (!canBuild(pile[j], pile[j - 1])) {
          throw const FormatException('Invalid tableau sequence');
        }
      }
    }
  }
}
