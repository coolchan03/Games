import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'sokoban_screen.dart';

final sokobanMetadata = GameMetadata(
  id: 'sokoban',
  category: 'LOGIC',
  icon: Icons.inventory_2_rounded,
  color: DesignSystem.gameOrange,
  builder: (context) => const SokobanScreen(),
  titleGetter: (context) => 'Sokoban',
  subtitleGetter: (context) => 'Push crates onto targets — endless solvable levels',
  popularity: Popularity.default_,
);
