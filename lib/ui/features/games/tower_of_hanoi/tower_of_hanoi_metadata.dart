import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'tower_of_hanoi_screen.dart';

final towerOfHanoiMetadata = GameMetadata(
  id: 'tower_of_hanoi',
  category: 'LOGIC',
  icon: Icons.stacked_bar_chart_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const TowerOfHanoiScreen(),
  titleGetter: (context) => 'Tower of Hanoi',
  subtitleGetter: (context) => 'Move the tower in the fewest moves',
  popularity: Popularity.default_,
);
