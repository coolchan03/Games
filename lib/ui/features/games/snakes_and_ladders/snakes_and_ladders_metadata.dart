import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'snakes_and_ladders_screen.dart';

final snakesAndLaddersMetadata = GameMetadata(
  id: 'snakes_and_ladders',
  category: 'BOARD',
  icon: Icons.stairs_rounded,
  color: DesignSystem.gameEmerald,
  builder: (context) => const SnakesAndLaddersScreen(),
  titleGetter: (context) => 'Snakes and Ladders',
  subtitleGetter: (context) => 'Classic race for 2-4 players',
  popularity: Popularity.default_,
);
