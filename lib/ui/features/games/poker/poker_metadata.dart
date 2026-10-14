import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'poker_screen.dart';
import 'poker_table.dart';
final texasHoldemMetadata = GameMetadata(
  id: 'texas_holdem', category: 'CARD', icon: Icons.style_outlined,
  color: DesignSystem.gameTeal, builder: (_) => const PokerScreen(),
  titleGetter: (_) => "Texas Hold'em",
  subtitleGetter: (_) => 'Fixed-limit, local 2-6 players or casual computer',
  popularity: Popularity.high,
);
final fiveCardDrawMetadata = GameMetadata(
  id: 'five_card_draw', category: 'CARD', icon: Icons.filter_5_outlined,
  color: DesignSystem.gameBlue, builder: (_) => const PokerScreen(variant: PokerVariant.draw),
  titleGetter: (_) => 'Five Card Draw',
  subtitleGetter: (_) => 'Draw, bet and split pots with virtual chips only',
  popularity: Popularity.high,
);
