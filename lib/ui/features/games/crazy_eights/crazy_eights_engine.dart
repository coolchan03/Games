import 'dart:math';

import '../common/cards/card.dart';

/// Crazy Eights for 2–4 players. Match the top card's suit or rank; eights
/// are wild and name a new suit. Can't play? Draw until you can (or the
/// stock runs out, then pass). First to empty their hand wins the round and
/// scores the cards left in other hands (8 = 50, faces 10, others pip).
class CrazyEightsGame {
  CrazyEightsGame(this.players, {Random? random}) : rng = random ?? Random() {
    deal();
  }

  final int players;
  final Random rng;
  late List<List<PlayingCard>> hands;
  late List<PlayingCard> stock;
  late List<PlayingCard> discard;
  late Suit activeSuit;
  int turn = 0;
  int? winner;
  final List<int> scores = List.filled(4, 0);
  int passes = 0;
  String log = '';

  PlayingCard get top => discard.last;

  void deal() {
    final deck = standardDeckCards()..shuffle(rng);
    final n = players == 2 ? 7 : 5;
    hands = [for (var p = 0; p < players; p++) [for (var i = 0; i < n; i++) deck.removeLast()]];
    // Turn up a non-eight starter.
    var i = deck.length - 1;
    while (deck[i].rank == Rank.eight) {
      i--;
    }
    discard = [deck.removeAt(i)];
    activeSuit = top.suit;
    stock = deck;
    winner = null;
    passes = 0;
    turn = 0;
    log = 'Starter: ${top.symbolString()}';
  }

  bool canPlay(PlayingCard c) => c.rank == Rank.eight || c.suit == activeSuit || c.rank == top.rank;

  List<PlayingCard> playable(int p) => hands[p].where(canPlay).toList();

  void _recycle() {
    if (stock.isNotEmpty || discard.length < 2) return;
    final keep = discard.removeLast();
    stock = discard..shuffle(rng);
    discard = [keep];
  }

  /// Draws one card for the current player; returns it or null if none left.
  PlayingCard? draw() {
    _recycle();
    if (stock.isEmpty) return null;
    final c = stock.removeLast();
    hands[turn].add(c);
    return c;
  }

  void play(PlayingCard c, {Suit? chosen}) {
    if (winner != null || !hands[turn].contains(c) || !canPlay(c)) {
      throw ArgumentError.value(c, 'card', 'Card is not in hand or is not playable');
    }
    hands[turn].remove(c);
    discard.add(c);
    activeSuit = c.rank == Rank.eight ? (chosen ?? c.suit) : c.suit;
    passes = 0;
    log = '${_name(turn)} played ${c.symbolString()}'
        '${c.rank == Rank.eight ? ' and chose ${activeSuit.symbolChar}' : ''}';
    if (hands[turn].isEmpty) {
      winner = turn;
      scores[turn] += [for (final h in hands) for (final x in h) _points(x)].fold(0, (a, b) => a + b);
      return;
    }
    turn = (turn + 1) % players;
  }

  void pass() {
    passes++;
    log = '${_name(turn)} cannot play and passes';
    turn = (turn + 1) % players;
    if (passes >= players) {
      // Blocked: lowest hand wins.
      final totals = [for (final h in hands) h.fold(0, (a, b) => a + _points(b))];
      winner = totals.indexOf(totals.reduce(min));
    }
  }

  static int _points(PlayingCard c) => c.rank == Rank.eight
      ? 50
      : c.rank.index >= Rank.ten.index && c.rank != Rank.ace
          ? 10
          : c.rank == Rank.ace
              ? 1
              : c.rank.numericValue;

  String _name(int p) => p == 0 ? 'You' : 'Player ${p + 1}';

  /// Suit the current player holds most of (for naming after an eight).
  Suit bestSuit(int p) {
    final counts = suitCounts(hands[p].where((c) => c.rank != Rank.eight));
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Computer turn: returns true if it played, false if it passed.
  bool aiTurn(int level) {
    while (playable(turn).isEmpty) {
      if (draw() == null) {
        pass();
        return false;
      }
    }
    final options = playable(turn);
    PlayingCard choice;
    if (level == 0) {
      choice = options[rng.nextInt(options.length)];
    } else {
      // Keep eights for last; prefer the suit we hold most of; on hard,
      // dump high cards and play to a suit the next player seems short in.
      final nonEights = options.where((c) => c.rank != Rank.eight).toList();
      if (nonEights.isEmpty) {
        choice = options.first;
      } else {
        final counts = suitCounts(hands[turn]);
        nonEights.sort((a, b) {
          final s = counts[b.suit]!.compareTo(counts[a.suit]!);
          if (s != 0 || level < 2) return s;
          return _points(b).compareTo(_points(a));
        });
        choice = nonEights.first;
      }
    }
    play(choice, chosen: choice.rank == Rank.eight ? bestSuit(turn) : null);
    return true;
  }
}
