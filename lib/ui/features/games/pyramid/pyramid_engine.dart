import 'dart:math';

import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

/// Pyramid solitaire: remove pairs of exposed cards that add up to 13
/// (Kings alone). Stock can be recycled twice.
class PyramidGame {
  PyramidGame({Random? random}) {
    final deck = standardDeckCards()..shuffle(random ?? Random());
    pyramid = [for (var i = 0; i < 28; i++) deck.removeLast()];
    stock = deck;
  }

  /// Row r (0-6) holds r+1 cards at indices r*(r+1)/2 ... ; null = removed.
  late List<PlayingCard?> pyramid;
  late List<PlayingCard> stock;
  List<PlayingCard> waste = [];
  int recycles = 2;
  final List<(List<PlayingCard?>, List<PlayingCard>, List<PlayingCard>, int)> _history = [];

  static int indexOf(int row, int col) => row * (row + 1) ~/ 2 + col;

  bool get won => pyramid.every((c) => c == null);
  bool get canUndo => _history.isNotEmpty;

  void _save() => _history.add((List.of(pyramid), List.of(stock), List.of(waste), recycles));

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    pyramid = h.$1;
    stock = h.$2;
    waste = h.$3;
    recycles = h.$4;
  }

  bool exposed(int row, int col) {
    if (pyramid[indexOf(row, col)] == null) return false;
    if (row == 6) return true;
    return pyramid[indexOf(row + 1, col)] == null && pyramid[indexOf(row + 1, col + 1)] == null;
  }

  /// Selectable sources: pyramid index (0-27) or -1 for the waste top.
  PlayingCard? cardAt(int src) =>
      src == -1 ? (waste.isEmpty ? null : waste.last) : pyramid[src];

  bool isFree(int src) {
    if (src == -1) return waste.isNotEmpty;
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c <= r; c++) {
        if (indexOf(r, c) == src) return exposed(r, c);
      }
    }
    return false;
  }

  void _remove(int src) {
    if (src == -1) {
      waste.removeLast();
    } else {
      pyramid[src] = null;
    }
  }

  /// Removes a lone King, or a pair summing to 13.
  bool remove(int a, [int? b]) {
    if (!isFree(a)) return false;
    final ca = cardAt(a)!;
    if (b == null) {
      if (aceLow(ca) != 13) return false;
      _save();
      _remove(a);
      return true;
    }
    if (a == b || !isFree(b)) return false;
    final cb = cardAt(b)!;
    if (aceLow(ca) + aceLow(cb) != 13) return false;
    // A card cannot pair with the card directly covering it, which is not
    // free anyway, so freedom checks are enough.
    _save();
    if (a == -1) {
      _remove(b);
      _remove(a);
    } else {
      _remove(a);
      _remove(b);
    }
    return true;
  }

  bool draw() {
    if (stock.isEmpty) {
      if (recycles == 0 || waste.isEmpty) return false;
      _save();
      stock = waste.reversed.toList();
      waste = [];
      recycles--;
      return true;
    }
    _save();
    waste.add(stock.removeLast());
    return true;
  }

  bool get stuck {
    if (won) return false;
    if (stock.isNotEmpty || (recycles > 0 && waste.isNotEmpty)) return false;
    final free = [for (var i = -1; i < 28; i++) if (isFree(i)) i];
    for (final a in free) {
      if (aceLow(cardAt(a)!) == 13) return false;
      for (final b in free) {
        if (a != b && aceLow(cardAt(a)!) + aceLow(cardAt(b)!) == 13) return false;
      }
    }
    return true;
  }
}
