import 'dart:math';

import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

/// Forty Thieves (Napoleon at St Helena): two decks, ten columns of four
/// face-up cards, eight foundations built up by suit from Ace. Columns
/// build down in the same suit and only one card moves at a time. The
/// stock is dealt one card at a time to the waste with no redeal.
class FortyThievesGame {
  FortyThievesGame({Random? random}) {
    final cards = [...standardDeckCards(), ...standardDeckCards()]..shuffle(random ?? Random());
    tableau = List.generate(10, (_) => [for (var k = 0; k < 4; k++) SCard(cards.removeLast(), up: true)]);
    stock = cards;
  }

  late List<List<SCard>> tableau;
  late List<PlayingCard> stock;
  List<PlayingCard> waste = [];
  final foundations = List.generate(8, (_) => <PlayingCard>[]);
  int moves = 0;
  final List<(List<List<SCard>>, List<PlayingCard>, List<PlayingCard>, List<List<PlayingCard>>, int)> _history = [];

  bool get won => foundations.every((f) => f.length == 13);
  bool get canUndo => _history.isNotEmpty;

  void _save() => _history.add((copyPiles(tableau), List.of(stock), List.of(waste), [for (final f in foundations) List.of(f)], moves));

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    tableau = h.$1;
    stock = h.$2;
    waste = h.$3;
    for (var i = 0; i < 8; i++) {
      foundations[i]
        ..clear()
        ..addAll(h.$4[i]);
    }
    moves = h.$5;
  }

  bool draw() {
    if (stock.isEmpty) return false;
    _save();
    waste.add(stock.removeLast());
    moves++;
    return true;
  }

  int? _foundationFor(PlayingCard c) {
    for (var f = 0; f < 8; f++) {
      final pile = foundations[f];
      if (pile.isEmpty ? aceLow(c) == 1 : pile.last.suit == c.suit && aceLow(pile.last) == aceLow(c) - 1) {
        return f;
      }
    }
    return null;
  }

  bool _fitsColumn(PlayingCard c, int col) {
    final t = tableau[col];
    if (t.isEmpty) return true;
    return t.last.suit == c.suit && t.last.value == aceLow(c) + 1;
  }

  /// Source: -1 = waste, 0..9 = column top. Moves to the foundation if
  /// possible, else to the best column (non-empty first).
  bool autoMove(int source) {
    final card = source < 0 ? (waste.isEmpty ? null : waste.last) : (tableau[source].isEmpty ? null : tableau[source].last.card);
    if (card == null) return false;
    final f = _foundationFor(card);
    int? dest;
    if (f == null) {
      for (var col = 0; col < 10; col++) {
        if (col != source && tableau[col].isNotEmpty && _fitsColumn(card, col)) {
          dest = col;
          break;
        }
      }
      if (dest == null && !(source >= 0 && tableau[source].length == 1)) {
        final empty = tableau.indexWhere((t) => t.isEmpty);
        if (empty >= 0) dest = empty;
      }
      if (dest == null) return false;
    }
    _save();
    if (source < 0) {
      waste.removeLast();
    } else {
      tableau[source].removeLast();
    }
    if (f != null) {
      foundations[f].add(card);
    } else {
      tableau[dest!].add(SCard(card, up: true));
    }
    moves++;
    return true;
  }

  bool moveTo(int source, int col) {
    final card = source < 0 ? (waste.isEmpty ? null : waste.last) : (tableau[source].isEmpty ? null : tableau[source].last.card);
    if (card == null || col == source || !_fitsColumn(card, col)) return false;
    _save();
    if (source < 0) {
      waste.removeLast();
    } else {
      tableau[source].removeLast();
    }
    tableau[col].add(SCard(card, up: true));
    moves++;
    return true;
  }
}
