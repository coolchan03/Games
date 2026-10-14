import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'sixteen_screen.dart';

final sixteenMetadata = GameMetadata(
  id: 'sixteen',
  category: 'SPATIAL',
  icon: Icons.swap_horiz_rounded,
  color: DesignSystem.gameTeal,
  builder: (context) => const SixteenScreen(),
  titleGetter: (context) => 'Sixteen',
  subtitleGetter: (context) => 'Shift rows and columns into order',
  popularity: Popularity.default_,
);
