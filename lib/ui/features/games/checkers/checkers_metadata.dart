import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'checkers_screen.dart';

final checkersMetadata = GameMetadata(
  id: 'checkers',
  category: 'BOARD',
  icon: Icons.circle_outlined,
  color: DesignSystem.gameRose,
  builder: (context) => const CheckersScreen(),
  titleGetter: (context) => 'Checkers',
  subtitleGetter: (context) => 'English checkers: local two-player or three AI levels',
  popularity: Popularity.high,
);
