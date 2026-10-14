import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'pyramid_screen.dart';

final pyramidMetadata = GameMetadata(
  id: 'pyramid',
  category: 'CARD',
  icon: Icons.change_history_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const PyramidScreen(),
  titleGetter: (context) => 'Pyramid Solitaire',
  subtitleGetter: (context) => 'Pair cards that add up to 13',
  popularity: Popularity.default_,
);
