import 'dart:math';

import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

/// Spider solitaire with 1, 2 or 4 suits (two decks, ten columns).
class SpiderGame {
  SpiderGame({this.suits = 1, Random? random}) {
    final suitList = switch (suits) {
      1 => [Suit.spades],
      2 => [Suit.spades, Suit.hearts],
      _ => Suit.values,
    };
    final cards = <PlayingCard>[];
    for (var deck = 0; deck < 8 ~/ suitList.length; deck++) {
      for (final s in suitList) {
        for (final r in Rank.values) {
          cards.add(PlayingCard(r, s));
        }
      }
    }
    cards.shuffle(random ?? Random());
    tableau = List.generate(10, (_) => <SCard>[]);
    for (var i = 0; i < 54; i++) {
      tableau[i % 10].add(SCard(cards.removeLast()));
    }
    for (final t in tableau) {
      t.last.up = true;
    }
    stock = [for (final c in cards) SCard(c)];
  }

  final int suits;
  late List<List<SCard>> tableau;
  late List<SCard> stock;
  int completed = 0;
  int moves = 0;
  int score = 500;
  final List<(List<List<SCard>>, List<SCard>, int, int, int)> _history = [];

  bool get won => completed == 8;
  bool get canUndo => _history.isNotEmpty;
  int get dealsLeft => stock.length ~/ 10;

  void _save() => _history.add(
      (copyPiles(tableau), [for (final c in stock) c.copy()], completed, moves, score));

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    tableau = h.$1;
    stock = h.$2;
    completed = h.$3;
    moves = h.$4;
    score = h.$5;
  }

  /// Index where the movable same-suit run at the bottom of [col] starts.
  int runStart(int col) {
    final t = tableau[col];
    if (t.isEmpty) return 0;
    var i = t.length - 1;
    while (i > 0 &&
        t[i - 1].up &&
        t[i - 1].suit == t[i].suit &&
        t[i - 1].value == t[i].value + 1) {
      i--;
    }
    return i;
  }

  bool canMove(int from, int index, int to) {
    if (from == to) return false;
    final src = tableau[from];
    if (index >= src.length || index < runStart(from)) return false;
    final dst = tableau[to];
    return dst.isEmpty || dst.last.value == src[index].value + 1;
  }

  bool move(int from, int index, int to) {
    if (!canMove(from, index, to)) return false;
    _save();
    final run = tableau[from].sublist(index);
    tableau[from].removeRange(index, tableau[from].length);
    if (tableau[from].isNotEmpty) tableau[from].last.up = true;
    tableau[to].addAll(run);
    moves++;
    score--;
    _collect(to);
    return true;
  }

  /// Best column for a run: one whose top continues the suit, then any
  /// legal non-empty column, then an empty one.
  int? autoTarget(int from, int index) {
    int? sameSuit, any, empty;
    for (var t = 0; t < 10; t++) {
      if (!canMove(from, index, t)) continue;
      final dst = tableau[t];
      if (dst.isEmpty) {
        if (index > 0) empty ??= t;
      } else if (dst.last.suit == tableau[from][index].suit) {
        sameSuit ??= t;
      } else {
        any ??= t;
      }
    }
    return sameSuit ?? any ?? empty;
  }

  bool get canDeal => stock.isNotEmpty && tableau.every((t) => t.isNotEmpty);

  bool deal() {
    if (!canDeal) return false;
    _save();
    for (var t = 0; t < 10; t++) {
      tableau[t].add(stock.removeLast()..up = true);
    }
    moves++;
    for (var t = 0; t < 10; t++) {
      _collect(t);
    }
    return true;
  }

  void _collect(int col) {
    final t = tableau[col];
    if (t.length < 13) return;
    final start = t.length - 13;
    final suit = t.last.suit;
    for (var k = 0; k < 13; k++) {
      final c = t[start + k];
      if (!c.up || c.suit != suit || c.value != 13 - k) return;
    }
    t.removeRange(start, t.length);
    if (t.isNotEmpty) t.last.up = true;
    completed++;
    score += 100;
  }
}
