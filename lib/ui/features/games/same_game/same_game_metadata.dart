import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'same_game_screen.dart';

final sameGameMetadata = GameMetadata(
  id: 'same_game',
  category: 'LOGIC',
  icon: Icons.bubble_chart_outlined,
  color: DesignSystem.gameRed,
  builder: (context) => const SameGameScreen(),
  titleGetter: (context) => 'Same Game',
  subtitleGetter: (context) => 'Clear groups of colour — boards always solvable',
  popularity: Popularity.default_,
);
