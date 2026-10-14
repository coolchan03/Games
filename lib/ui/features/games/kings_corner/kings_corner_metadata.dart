import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'kings_corner_screen.dart';

final kingsCornerMetadata = GameMetadata(
  id: 'kings_corner',
  category: 'CARD',
  icon: Icons.auto_awesome_motion_outlined,
  color: DesignSystem.gameTeal,
  builder: (_) => const KingsCornerScreen(),
  titleGetter: (_) => "King's Corner",
  subtitleGetter: (_) => 'Build alternating-color piles with 2-4 friends or a bot',
  popularity: Popularity.default_,
);
