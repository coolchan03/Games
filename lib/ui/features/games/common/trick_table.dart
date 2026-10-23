import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'card_view.dart';
import 'cards/card.dart';

/// Four-seat card table used by Hearts, Spades and Oh Hell.
///
/// Seat 0 is the human (bottom), then play proceeds clockwise:
/// 1 = West (left), 2 = North (top), 3 = East (right).
class TrickTable extends StatelessWidget {
  const TrickTable({
    super.key,
    required this.names,
    required this.info,
    required this.trickCards,
    required this.trickLeader,
    this.active,
    this.winner,
    this.center,
  });

  final List<String> names;
  final List<String> info;
  final List<PlayingCard> trickCards;
  final int trickLeader;
  final int? active;
  final int? winner;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget seat(int i) {
      final isActive = active == i;
      final isWinner = winner == i;
      return Container(
        constraints: const BoxConstraints(maxWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isWinner
              ? colors.tertiaryContainer
              : isActive
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(names[i],
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(info[i],
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      );
    }

    PlayingCard? cardFor(int seat) {
      final idx = (seat - trickLeader + 4) % 4;
      return idx < trickCards.length ? trickCards[idx] : null;
    }

    const w = 50.0;
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E6B45),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(children: [
          Align(alignment: const Alignment(0, -.95), child: seat(2)),
          Align(alignment: const Alignment(-.97, -.3), child: seat(1)),
          Align(alignment: const Alignment(.97, -.3), child: seat(3)),
          Align(alignment: const Alignment(0, .97), child: seat(0)),
          if (center != null) Align(alignment: Alignment.center, child: center),
          for (final (s, a) in const [
            (0, Alignment(0, .5)),
            (1, Alignment(-.42, .15)),
            (2, Alignment(0, -.25)),
            (3, Alignment(.42, .15)),
          ])
            if (cardFor(s) != null)
              Align(alignment: a, child: CardView(card: cardFor(s), width: w)),
        ]),
      ),
    );
  }
}

/// How long the computer may think for one card, by difficulty.
int thinkMillis(int level) => switch (level) {
      0 => 0,
      1 => kIsWeb ? 250 : 500,
      _ => kIsWeb ? 700 : 1500,
    };
