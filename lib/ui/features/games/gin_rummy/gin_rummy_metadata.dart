import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'gin_rummy_screen.dart';

final ginRummyMetadata = GameMetadata(
  id: 'gin_rummy',
  category: 'CARD',
  icon: Icons.view_week_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const GinRummyScreen(),
  titleGetter: (context) => 'Gin Rummy',
  subtitleGetter: (context) => 'Melds, deadwood and knocking against the computer',
  popularity: Popularity.default_,
);
