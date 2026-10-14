import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'spades_screen.dart';

final spadesMetadata = GameMetadata(
  id: 'spades',
  category: 'CARD',
  icon: Icons.filter_vintage_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const SpadesScreen(),
  titleGetter: (context) => 'Spades',
  subtitleGetter: (context) => 'Partnership bidding and tricks with computer players',
);
