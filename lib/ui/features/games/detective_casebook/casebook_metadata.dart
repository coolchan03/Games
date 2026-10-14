import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'casebook_screen.dart';

final detectiveCasebookMetadata = GameMetadata(
  id: 'detective_casebook',
  category: 'LOGIC',
  icon: Icons.manage_search_rounded,
  color: DesignSystem.gameRose,
  builder: (context) => const DetectiveCasebookScreen(),
  titleGetter: (context) => 'Detective Casebook',
  subtitleGetter: (context) => 'Solve murders and thefts using evidence and logic grids',
  popularity: Popularity.high,
);
