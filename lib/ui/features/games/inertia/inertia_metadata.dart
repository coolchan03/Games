import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'inertia_screen.dart';

final inertiaMetadata = GameMetadata(
  id: 'inertia',
  category: 'LOGIC',
  icon: Icons.diamond_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const InertiaScreen(),
  titleGetter: (context) => 'Inertia',
  subtitleGetter: (context) => 'Slide to collect every gem — avoid the mines',
  popularity: Popularity.default_,
);
