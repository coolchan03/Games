import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'golf_solitaire_screen.dart';

final golfSolitaireMetadata = GameMetadata(
  id: 'golf_solitaire',
  category: 'CARD',
  icon: Icons.golf_course_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const GolfSolitaireScreen(),
  titleGetter: (context) => 'Golf Solitaire',
  subtitleGetter: (context) => 'Clear the columns one rank up or down',
  popularity: Popularity.default_,
);
