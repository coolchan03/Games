import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'crazy_eights_screen.dart';

final crazyEightsMetadata = GameMetadata(
  id: 'crazy_eights',
  category: 'CARD',
  icon: Icons.filter_8_rounded,
  color: DesignSystem.gameRed,
  builder: (context) => const CrazyEightsScreen(),
  titleGetter: (context) => 'Crazy Eights',
  subtitleGetter: (context) => 'Match suit or rank — eights are wild',
  popularity: Popularity.default_,
);
