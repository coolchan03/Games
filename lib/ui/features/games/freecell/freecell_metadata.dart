import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'freecell_screen.dart';

final freeCellMetadata = GameMetadata(
  id: 'freecell',
  category: 'CARD',
  icon: Icons.grid_view_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const FreeCellScreen(),
  titleGetter: (context) => 'FreeCell',
  subtitleGetter: (context) => 'Numbered deals, almost all solvable',
  popularity: Popularity.default_,
);
