import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'war_screen.dart';

final warMetadata = GameMetadata(
  id: 'war',
  category: 'CARD',
  icon: Icons.flash_on_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const WarScreen(),
  titleGetter: (context) => 'War',
  subtitleGetter: (context) => 'The classic card-flipping game',
  popularity: Popularity.default_,
);
