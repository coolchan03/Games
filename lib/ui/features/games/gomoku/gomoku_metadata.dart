import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'gomoku_screen.dart';

final gomokuMetadata = GameMetadata(
  id: 'gomoku',
  category: 'BOARD',
  icon: Icons.circle_outlined,
  color: DesignSystem.gameAmber,
  builder: (context) => const GomokuScreen(),
  titleGetter: (context) => 'Gomoku',
  subtitleGetter: (context) => 'Five in a row on a 15×15 board',
  popularity: Popularity.default_,
);
