import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import '../common/solitaire_kit.dart';

/// Aces Up (also called Four Aces / Idiot's Delight).
class AcesUpGame {
  AcesUpGame({Random? random}) {
    stock = standardDeckCards()..shuffle(random ?? Random());
    deal();
  }
  late List<PlayingCard> stock;
  final piles = List.generate(4, (_) => <PlayingCard>[]);
  int discarded = 0;
  final List<(List<List<PlayingCard>>, List<PlayingCard>, int)> _history = [];

  static int value(PlayingCard c) => c.rank == Rank.ace ? 14 : c.rank.numericValue;

  void _save() => _history.add(([for (final p in piles) List.of(p)], List.of(stock), discarded));
  bool get canUndo => _history.isNotEmpty;
  void undo() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    for (var i = 0; i < 4; i++) {
      piles[i]
        ..clear()
        ..addAll(h.$1[i]);
    }
    stock = h.$2;
    discarded = h.$3;
  }

  bool deal() {
    if (stock.isEmpty) return false;
    if (discarded > 0 || piles.any((p) => p.isNotEmpty)) _save();
    for (final p in piles) {
      if (stock.isNotEmpty) p.add(stock.removeLast());
    }
    return true;
  }

  /// A top card can be discarded if a higher card of its suit is on top of
  /// another pile.
  bool canDiscard(int i) {
    if (piles[i].isEmpty) return false;
    final c = piles[i].last;
    return piles.any((p) => p.isNotEmpty && p != piles[i] && p.last.suit == c.suit && value(p.last) > value(c));
  }

  bool tap(int i) {
    if (canDiscard(i)) {
      _save();
      piles[i].removeLast();
      discarded++;
      return true;
    }
    // Otherwise move it into an empty pile if there is one.
    if (piles[i].length > 1) {
      final empty = piles.indexWhere((p) => p.isEmpty);
      if (empty >= 0) {
        _save();
        piles[empty].add(piles[i].removeLast());
        return true;
      }
    }
    return false;
  }

  bool get won => stock.isEmpty && piles.every((p) => p.length == 1 && p.first.rank == Rank.ace);
  bool get stuck =>
      stock.isEmpty && !won && !List.generate(4, (i) => i).any((i) => canDiscard(i) || (piles[i].length > 1 && piles.any((p) => p.isEmpty)));
}

class AcesUpScreen extends StatefulWidget {
  const AcesUpScreen({super.key});
  @override
  State<AcesUpScreen> createState() => _AcesUpScreenState();
}

class _AcesUpScreenState extends State<AcesUpScreen> {
  AcesUpGame game = AcesUpGame();

  @override
  Widget build(BuildContext context) {
    final left = 52 - game.discarded;
    return GameScaffold(
      gameId: 'aces_up',
      completed: game.won,
      title: 'Aces Up',
      onNewGame: () => setState(() => game = AcesUpGame()),
      rules: 'Deal one card onto each of four piles. Whenever two piles show '
          'cards of the same suit, tap the lower one to discard it (aces are '
          'high). Tap a card to move it into an empty pile. When stuck, deal '
          'four more. You win by ending with only the four aces.',
      children: [
        Row(children: [
          Expanded(
            child: StatusBanner(
              game.won ? 'Only the aces remain — you win!' : game.stuck ? 'No moves left · $left cards remain' : '$left cards remain · ${game.stock.length} in stock',
              highlight: game.won || game.stuck,
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: game.canUndo ? () => setState(game.undo) : null,
            icon: const Icon(Icons.undo),
          ),
        ]),
        LayoutBuilder(builder: (context, box) {
          final w = columnWidth(box.maxWidth - 16, 5, maxW: 80);
          return Felt(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 4; i++)
                  CardColumn(
                    cards: [for (final c in game.piles[i]) SCard(c, up: true)],
                    width: w,
                    maxHeight: w * 6,
                    highlight: game.canDiscard(i),
                    onTapCard: (k) => k == game.piles[i].length - 1 ? setState(() => game.tap(i)) : null,
                  ),
                GestureDetector(
                  onTap: () => setState(game.deal),
                  child: CardView(faceDown: game.stock.isNotEmpty, width: w),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
