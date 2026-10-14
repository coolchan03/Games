import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'air_hockey_screen.dart';

final airHockeyMetadata = GameMetadata(
  id: 'air_hockey',
  category: 'BOARD',
  icon: Icons.sports_hockey_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const AirHockeyScreen(),
  titleGetter: (context) => 'Air Hockey',
  subtitleGetter: (context) => 'Fast table hockey — vs computer or two thumbs',
  popularity: Popularity.default_,
);
