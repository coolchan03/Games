import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'aces_up_screen.dart';

final acesUpMetadata = GameMetadata(
  id: 'aces_up',
  category: 'CARD',
  icon: Icons.filter_4_rounded,
  color: DesignSystem.gameRose,
  builder: (context) => const AcesUpScreen(),
  titleGetter: (context) => 'Aces Up',
  subtitleGetter: (context) => 'Discard down to the four aces',
  popularity: Popularity.default_,
);
