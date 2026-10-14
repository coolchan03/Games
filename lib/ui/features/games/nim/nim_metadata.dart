import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'nim_screen.dart';

final nimMetadata = GameMetadata(
  id: 'nim',
  category: 'LOGIC',
  icon: Icons.view_week_outlined,
  color: DesignSystem.gameRed,
  builder: (context) => const NimScreen(),
  titleGetter: (context) => 'Nim',
  subtitleGetter: (context) => 'Take matches — normal or misère, perfect AI',
  popularity: Popularity.default_,
);
