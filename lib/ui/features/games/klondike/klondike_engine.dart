import 'dart:math';

import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

/// Where a selection or move starts/ends in Klondike.
enum KPile { stock, waste, foundation, tableau }

class KRef {
  const KRef(this.pile, [this.index = 0, this.card = 0]);
  final KPile pile;

  /// Foundation 0-3 or tableau column 0-6.
  final int index;

  /// Position within a tableau column (start of the moved run).
  final int card;

  @override
  bool operator ==(Object o) =>
      o is KRef && o.pile == pile && o.index == index && o.card == card;
  @override
  int get hashCode => Object.hash(pile, index, card);
}

/// Klondike solitaire rules. Logic follows the standard game as implemented
/// in many FOSS solitaires (e.g. PySolFC, GPL-3.0); written fresh in Dart.
class KlondikeGame {
  KlondikeGame({this.drawThree = false, Random? random}) {
    final deck = standardDeckCards()..shuffle(random ?? Random());
    for (var col = 0; col < 7; col++) {
      tableau.add([
        for (var k = 0; k <= col; k++) SCard(deck.removeLast(), up: k == col),
      ]);
    }
    stock = [for (final c in deck) SCard(c)];
  }

  KlondikeGame._empty(this.drawThree);

  final bool drawThree;
  List<SCard> stock = [];
  List<SCard> waste = [];
  List<List<SCard>> foundations = [[], [], [], []];
  List<List<SCard>> tableau = [];
  int moves = 0;
  final List<KlondikeGame> _history = [];

  KlondikeGame _snapshot() => KlondikeGame._empty(drawThree)
    ..stock = [for (final c in stock) c.copy()]
    ..waste = [for (final c in waste) c.copy()]
    ..foundations = copyPiles(foundations)
    ..tableau = copyPiles(tableau)
    ..moves = moves;

  void _save() {
    _history.add(_snapshot());
    if (_history.length > 200) _history.removeAt(0);
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;
    final s = _history.removeLast();
    stock = s.stock;
    waste = s.waste;
    foundations = s.foundations;
    tableau = s.tableau;
    moves = s.moves;
  }

  bool get won => foundations.every((f) => f.length == 13);

  void drawStock() {
    _save();
    if (stock.isEmpty) {
      if (waste.isEmpty) {
        _history.removeLast();
        return;
      }
      stock = [for (final c in waste.reversed) c..up = false];
      waste = [];
    } else {
      final n = drawThree ? 3 : 1;
      for (var i = 0; i < n && stock.isNotEmpty; i++) {
        waste.add(stock.removeLast()..up = true);
      }
    }
    moves++;
  }

  List<SCard> _cardsAt(KRef from) {
    switch (from.pile) {
      case KPile.waste:
        return waste.isEmpty ? [] : [waste.last];
      case KPile.foundation:
        final f = foundations[from.index];
        return f.isEmpty ? [] : [f.last];
      case KPile.tableau:
        final t = tableau[from.index];
        if (from.card >= t.length || !t[from.card].up) return [];
        return t.sublist(from.card);
      case KPile.stock:
        return [];
    }
  }

  static bool _isRun(List<SCard> run) {
    for (var i = 1; i < run.length; i++) {
      if (run[i].red == run[i - 1].red || run[i].value != run[i - 1].value - 1) {
        return false;
      }
    }
    return true;
  }

  bool canMove(KRef from, KRef to) {
    final cards = _cardsAt(from);
    if (cards.isEmpty || !_isRun(cards)) return false;
    if (from.pile == to.pile && from.index == to.index) return false;
    final first = cards.first;
    switch (to.pile) {
      case KPile.foundation:
        if (cards.length != 1) return false;
        final f = foundations[to.index];
        if (f.isEmpty) return first.value == 1;
        return f.last.suit == first.suit && f.last.value == first.value - 1;
      case KPile.tableau:
        final t = tableau[to.index];
        if (t.isEmpty) return first.value == 13;
        final top = t.last;
        return top.up && top.red != first.red && top.value == first.value + 1;
      case KPile.stock:
      case KPile.waste:
        return false;
    }
  }

  bool move(KRef from, KRef to) {
    if (!canMove(from, to)) return false;
    _save();
    final cards = _cardsAt(from);
    switch (from.pile) {
      case KPile.waste:
        waste.removeLast();
      case KPile.foundation:
        foundations[from.index].removeLast();
      case KPile.tableau:
        final t = tableau[from.index];
        t.removeRange(from.card, t.length);
        if (t.isNotEmpty) t.last.up = true;
      case KPile.stock:
        break;
    }
    (to.pile == KPile.foundation ? foundations[to.index] : tableau[to.index])
        .addAll(cards);
    moves++;
    return true;
  }

  /// Best automatic destination for a tapped card: foundation first,
  /// then a tableau column (preferring non-empty ones).
  KRef? autoTarget(KRef from) {
    final cards = _cardsAt(from);
    if (cards.isEmpty) return null;
    if (cards.length == 1) {
      for (var f = 0; f < 4; f++) {
        final to = KRef(KPile.foundation, f);
        if (canMove(from, to)) return to;
      }
    }
    KRef? empty;
    for (var t = 0; t < 7; t++) {
      final to = KRef(KPile.tableau, t);
      if (!canMove(from, to)) continue;
      if (tableau[t].isEmpty) {
        // Moving a king from an otherwise empty column is pointless.
        if (from.pile == KPile.tableau && from.card == 0) continue;
        empty ??= to;
      } else {
        return to;
      }
    }
    return empty;
  }

  /// Moves every card that can safely go to the foundations.
  int autoFinish() {
    var count = 0;
    var progress = true;
    while (progress) {
      progress = false;
      final sources = [
        const KRef(KPile.waste),
        for (var t = 0; t < 7; t++)
          if (tableau[t].isNotEmpty) KRef(KPile.tableau, t, tableau[t].length - 1),
      ];
      for (final s in sources) {
        for (var f = 0; f < 4; f++) {
          if (move(s, KRef(KPile.foundation, f))) {
            count++;
            progress = true;
            break;
          }
        }
      }
    }
    return count;
  }

  /// All cards are face up and the stock is used: the game can finish itself.
  bool get canAutoFinish =>
      stock.isEmpty && waste.isEmpty && tableau.every((t) => t.every((c) => c.up));
}
