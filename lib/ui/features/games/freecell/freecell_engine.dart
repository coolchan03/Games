import '../common/cards/card.dart';
import '../common/solitaire_kit.dart';

enum FPile { cell, foundation, tableau }

class FRef {
  const FRef(this.pile, this.index, [this.card = 0]);
  final FPile pile;
  final int index;
  final int card;
  @override
  bool operator ==(Object o) =>
      o is FRef && o.pile == pile && o.index == index && o.card == card;
  @override
  int get hashCode => Object.hash(pile, index, card);
}

/// Deals the classic numbered FreeCell games (1–32000) with the well-known
/// Microsoft linear congruential shuffle, so "Game #1" matches other
/// FreeCell implementations.
List<PlayingCard> microsoftDeal(int gameNumber) {
  const suits = [Suit.clubs, Suit.diamonds, Suit.hearts, Suit.spades];
  final ranks = [Rank.ace, ...Rank.values.where((r) => r != Rank.ace)];
  final cards = List.generate(52, (i) => i);
  var seed = gameNumber;
  final out = <PlayingCard>[];
  while (cards.isNotEmpty) {
    seed = (seed * 214013 + 2531011) & 0xffffffff;
    final r = (seed >> 16) & 0x7fff;
    final i = r % cards.length;
    final tmp = cards[i];
    cards[i] = cards.last;
    cards[cards.length - 1] = tmp;
    final c = cards.removeLast();
    out.add(PlayingCard(ranks[c ~/ 4], suits[c % 4]));
  }
  return out;
}

class FreeCellGame {
  FreeCellGame(this.number) {
    final deal = microsoftDeal(number);
    tableau = List.generate(8, (_) => <SCard>[]);
    for (var i = 0; i < 52; i++) {
      tableau[i % 8].add(SCard(deal[i], up: true));
    }
  }

  final int number;
  List<SCard?> cells = List.filled(4, null);
  List<List<SCard>> foundations = [[], [], [], []];
  late List<List<SCard>> tableau;
  int moves = 0;
  final List<(List<SCard?>, List<List<SCard>>, List<List<SCard>>, int)> _history = [];

  bool get won => foundations.every((f) => f.length == 13);
  bool get canUndo => _history.isNotEmpty;

  void _save() => _history.add((
        [for (final c in cells) c?.copy()],
        copyPiles(foundations),
        copyPiles(tableau),
        moves,
      ));

  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    cells = h.$1;
    foundations = h.$2;
    tableau = h.$3;
    moves = h.$4;
  }

  int get freeCells => cells.where((c) => c == null).length;
  int get emptyColumns => tableau.where((t) => t.isEmpty).length;

  /// Longest run that can move using free cells and empty columns.
  int maxRun({required bool toEmpty}) =>
      (freeCells + 1) * (1 << (emptyColumns - (toEmpty ? 1 : 0)));

  List<SCard> _cards(FRef from) {
    switch (from.pile) {
      case FPile.cell:
        final c = cells[from.index];
        return c == null ? [] : [c];
      case FPile.foundation:
        final f = foundations[from.index];
        return f.isEmpty ? [] : [f.last];
      case FPile.tableau:
        final t = tableau[from.index];
        return from.card < t.length ? t.sublist(from.card) : [];
    }
  }

  static bool isRun(List<SCard> run) {
    for (var i = 1; i < run.length; i++) {
      if (run[i].red == run[i - 1].red || run[i].value != run[i - 1].value - 1) {
        return false;
      }
    }
    return true;
  }

  bool canMove(FRef from, FRef to) {
    final cards = _cards(from);
    if (cards.isEmpty || !isRun(cards)) return false;
    if (from.pile == to.pile && from.index == to.index) return false;
    final first = cards.first;
    switch (to.pile) {
      case FPile.cell:
        return cards.length == 1 && cells[to.index] == null;
      case FPile.foundation:
        if (cards.length != 1) return false;
        final f = foundations[to.index];
        return f.isEmpty
            ? first.value == 1
            : f.last.suit == first.suit && f.last.value == first.value - 1;
      case FPile.tableau:
        final t = tableau[to.index];
        if (cards.length > maxRun(toEmpty: t.isEmpty)) return false;
        if (t.isEmpty) return true;
        return t.last.red != first.red && t.last.value == first.value + 1;
    }
  }

  bool move(FRef from, FRef to) {
    if (!canMove(from, to)) return false;
    _save();
    final cards = _cards(from);
    switch (from.pile) {
      case FPile.cell:
        cells[from.index] = null;
      case FPile.foundation:
        foundations[from.index].removeLast();
      case FPile.tableau:
        tableau[from.index].removeRange(from.card, tableau[from.index].length);
    }
    switch (to.pile) {
      case FPile.cell:
        cells[to.index] = cards.single;
      case FPile.foundation:
        foundations[to.index].add(cards.single);
      case FPile.tableau:
        tableau[to.index].addAll(cards);
    }
    moves++;
    return true;
  }

  /// Detect actual legal transfers without mutating the deal.
  bool get noMovesLeft {
    if (won) return false;
    final sources = <FRef>[
      for (var c = 0; c < cells.length; c++)
        if (cells[c] != null) FRef(FPile.cell, c),
      for (var f = 0; f < foundations.length; f++)
        if (foundations[f].isNotEmpty) FRef(FPile.foundation, f),
      for (var t = 0; t < tableau.length; t++)
        for (var i = 0; i < tableau[t].length; i++)
          FRef(FPile.tableau, t, i),
    ];
    for (final from in sources) {
      for (var c = 0; c < cells.length; c++) {
        if (canMove(from, FRef(FPile.cell, c))) return false;
      }
      for (var f = 0; f < foundations.length; f++) {
        if (canMove(from, FRef(FPile.foundation, f))) return false;
      }
      for (var t = 0; t < tableau.length; t++) {
        if (!canMove(from, FRef(FPile.tableau, t))) continue;
        if (tableau[t].isEmpty &&
            from.pile == FPile.tableau && from.card == 0) continue;
        return false;
      }
    }
    return true;
  }

  FRef? autoTarget(FRef from) {
    final cards = _cards(from);
    if (cards.isEmpty) return null;
    if (cards.length == 1) {
      for (var f = 0; f < 4; f++) {
        if (canMove(from, FRef(FPile.foundation, f))) return FRef(FPile.foundation, f);
      }
    }
    FRef? empty;
    for (var t = 0; t < 8; t++) {
      final to = FRef(FPile.tableau, t);
      if (!canMove(from, to)) continue;
      if (tableau[t].isEmpty) {
        if (!(from.pile == FPile.tableau && from.card == 0)) empty ??= to;
      } else {
        return to;
      }
    }
    if (empty != null) return empty;
    if (cards.length == 1 && from.pile != FPile.cell) {
      for (var c = 0; c < 4; c++) {
        if (cells[c] == null) return FRef(FPile.cell, c);
      }
    }
    return null;
  }

  /// A card is safe to auto-play when both opposite-colour cards one rank
  /// lower are already on the foundations.
  int _height(Suit s) => foundations
      .firstWhere((f) => f.isNotEmpty && f.first.suit == s, orElse: () => [])
      .length;

  bool _safe(SCard c) {
    if (c.value <= 2) return true;
    final opposite = c.red ? [Suit.clubs, Suit.spades] : [Suit.hearts, Suit.diamonds];
    return opposite.every((s) => _height(s) >= c.value - 1);
  }

  /// Plays safe cards to the foundations; returns how many moved.
  int autoPlay() {
    var n = 0;
    var progress = true;
    while (progress) {
      progress = false;
      final sources = [
        for (var c = 0; c < 4; c++) if (cells[c] != null) FRef(FPile.cell, c),
        for (var t = 0; t < 8; t++)
          if (tableau[t].isNotEmpty) FRef(FPile.tableau, t, tableau[t].length - 1),
      ];
      for (final s in sources) {
        final card = _cards(s).first;
        if (!_safe(card)) continue;
        for (var f = 0; f < 4; f++) {
          final to = FRef(FPile.foundation, f);
          if (canMove(s, to)) {
            // Auto moves share one undo step with the move that caused them.
            final h = _history.length;
            move(s, to);
            _history.removeRange(h, _history.length);
            n++;
            progress = true;
            break;
          }
        }
      }
    }
    return n;
  }
}
