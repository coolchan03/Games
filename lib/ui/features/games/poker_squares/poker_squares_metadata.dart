import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'poker_squares_screen.dart';

final pokerSquaresMetadata = GameMetadata(
  id: 'poker_squares',
  category: 'CARD',
  icon: Icons.grid_4x4_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const PokerSquaresScreen(),
  titleGetter: (context) => 'Poker Squares',
  subtitleGetter: (context) => 'Build ten poker hands in a 5×5 grid',
  popularity: Popularity.default_,
);
