import 'dart:math';

import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

/// Golf solitaire: clear seven columns by playing cards one rank above or
/// below the waste card. Kings stop the run (no wrapping), as in the
/// traditional rules.
class GolfGame {
  GolfGame({Random? random, this.wrap = false}) {
    final deck = standardDeckCards()..shuffle(random ?? Random());
    columns = List.generate(7, (_) => [for (var k = 0; k < 5; k++) deck.removeLast()]);
    waste = [deck.removeLast()];
    stock = deck;
  }

  final bool wrap;
  late List<List<PlayingCard>> columns;
  late List<PlayingCard> waste;
  late List<PlayingCard> stock;
  final List<(List<List<PlayingCard>>, List<PlayingCard>, List<PlayingCard>)> _history = [];

  bool get canUndo => _history.isNotEmpty;
  int get remaining => columns.fold(0, (s, c) => s + c.length);
  bool get won => remaining == 0;
  bool get stuck =>
      !won && stock.isEmpty && !List.generate(7, (i) => i).any(canPlay);

  void _save() => _history.add(([for (final c in columns) List.of(c)], List.of(waste), List.of(stock)));

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    columns = h.$1;
    waste = h.$2;
    stock = h.$3;
  }

  bool canPlay(int col) {
    if (columns[col].isEmpty) return false;
    final a = aceLow(columns[col].last), b = aceLow(waste.last);
    if (!wrap && b == 13) return false;
    final d = (a - b).abs();
    return d == 1 || (wrap && d == 12);
  }

  bool play(int col) {
    if (!canPlay(col)) return false;
    _save();
    waste.add(columns[col].removeLast());
    return true;
  }

  bool draw() {
    if (stock.isEmpty) return false;
    _save();
    waste.add(stock.removeLast());
    return true;
  }
}
