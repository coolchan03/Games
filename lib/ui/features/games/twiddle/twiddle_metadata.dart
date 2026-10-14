import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'twiddle_screen.dart';

final twiddleMetadata = GameMetadata(
  id: 'twiddle',
  category: 'SPATIAL',
  icon: Icons.rotate_90_degrees_cw_rounded,
  color: DesignSystem.gamePurple,
  builder: (context) => const TwiddleScreen(),
  titleGetter: (context) => 'Twiddle',
  subtitleGetter: (context) => 'Rotate blocks to restore the order',
  popularity: Popularity.default_,
);
