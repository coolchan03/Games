import 'dart:math';

import '../common/cards/card.dart';

/// Go Fish for 2–4 players. Ask another player for a rank you hold; take all
/// their cards of that rank and ask again, or "go fish" from the pond. A
/// fished card of the asked rank also earns another turn. Four of a kind
/// make a book; most books wins.
class GoFishGame {
  GoFishGame(this.players, {Random? random}) : rng = random ?? Random() {
    final deck = standardDeckCards()..shuffle(rng);
    final n = players <= 3 ? 7 : 5;
    hands = [for (var p = 0; p < players; p++) [for (var i = 0; i < n; i++) deck.removeLast()]];
    pond = deck;
    books = List.generate(players, (_) => <Rank>[]);
    for (var p = 0; p < players; p++) {
      _collectBooks(p);
    }
  }

  final int players;
  final Random rng;
  late List<List<PlayingCard>> hands;
  late List<PlayingCard> pond;
  late List<List<Rank>> books;
  int turn = 0;
  String log = '';

  /// Ranks each player is known to hold (they asked for them).
  final Map<int, Set<Rank>> known = {};

  bool get over => books.fold(0, (s, b) => s + b.length) == 13;
  List<int> get winners {
    final best = books.map((b) => b.length).reduce(max);
    return [for (var p = 0; p < players; p++) if (books[p].length == best) p];
  }

  String name(int p) => p == 0 ? 'You' : 'Player ${p + 1}';

  void _collectBooks(int p) {
    for (final r in Rank.values) {
      if (hands[p].where((c) => c.rank == r).length == 4) {
        hands[p].removeWhere((c) => c.rank == r);
        books[p].add(r);
        known[p]?.remove(r);
      }
    }
  }

  void _refill(int p) {
    if (hands[p].isEmpty && pond.isNotEmpty) hands[p].add(pond.removeLast());
  }

  void _advance() {
    if (over) return;
    for (var k = 1; k <= players; k++) {
      final p = (turn + k) % players;
      _refill(p);
      if (hands[p].isNotEmpty) {
        turn = p;
        return;
      }
    }
  }

  List<Rank> askable(int p) => hands[p].map((c) => c.rank).toSet().toList();

  /// Current player asks [target] for [rank]. Returns true if the same
  /// player continues.
  bool ask(int target, Rank rank) {
    if (over || target < 0 || target >= players || target == turn ||
        hands[target].isEmpty || !askable(turn).contains(rank)) {
      throw ArgumentError('Must ask another active player for a rank you hold');
    }
    final asker = turn;
    (known[asker] ??= {}).add(rank);
    final got = hands[target].where((c) => c.rank == rank).toList();
    final label = rank == Rank.ten ? '10' : rank.asciiChar;
    if (got.isNotEmpty) {
      hands[target].removeWhere((c) => c.rank == rank);
      hands[asker].addAll(got);
      known[target]?.remove(rank);
      log = '${name(asker)} took ${got.length} × $label from ${name(target)}';
      _collectBooks(asker);
      _refill(target);
      _refill(asker);
      if (hands[asker].isEmpty) {
        _advance();
        return false;
      }
      return true;
    }
    if (pond.isEmpty) {
      log = '${name(target)}: "Go fish!" — the pond is empty';
      _advance();
      return false;
    }
    final fish = pond.removeLast();
    hands[asker].add(fish);
    _collectBooks(asker);
    if (fish.rank == rank) {
      log = '${name(asker)} fished the $label they asked for — go again';
      _refill(asker);
      if (hands[asker].isEmpty) {
        _advance();
        return false;
      }
      return true;
    }
    log = '${name(target)}: "Go fish!" ${asker == 0 ? 'You drew ${fish.symbolString()}' : ''}';
    _advance();
    return false;
  }

  /// Computer ask: hard remembers what others asked for.
  (int, Rank) aiAsk(int level) {
    final me = turn;
    final mine = askable(me);
    final others = [for (var p = 0; p < players; p++) if (p != me && hands[p].isNotEmpty) p];
    if (level > 0) {
      for (final p in others) {
        for (final r in known[p] ?? <Rank>{}) {
          if (mine.contains(r) && (level == 2 || rng.nextBool())) return (p, r);
        }
      }
    }
    // Ask for the rank we hold most of.
    mine.sort((a, b) => hands[me].where((c) => c.rank == b).length - hands[me].where((c) => c.rank == a).length);
    final rank = level == 0 ? mine[rng.nextInt(mine.length)] : mine.first;
    return (others[rng.nextInt(others.length)], rank);
  }
}
