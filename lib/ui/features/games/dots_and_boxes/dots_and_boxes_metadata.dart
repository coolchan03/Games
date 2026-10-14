import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'dots_and_boxes_screen.dart';

final dotsAndBoxesMetadata = GameMetadata(
  id: 'dots_and_boxes',
  category: 'BOARD',
  icon: Icons.border_all_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const DotsAndBoxesScreen(),
  titleGetter: (context) => 'Dots and Boxes',
  subtitleGetter: (context) => 'Close boxes, avoid giving away chains',
  popularity: Popularity.default_,
);
