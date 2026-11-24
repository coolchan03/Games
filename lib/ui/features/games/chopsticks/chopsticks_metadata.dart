import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'chopsticks_screen.dart';

final chopsticksMetadata = GameMetadata(
  id: 'chopsticks',
  category: 'LOGIC',
  icon: Icons.back_hand_outlined,
  color: DesignSystem.gameOrange,
  builder: (context) => const ChopsticksScreen(),
  titleGetter: (context) => 'Chopsticks',
  subtitleGetter: (context) => 'The finger game — tap to attack or split, solved AI',
  popularity: Popularity.default_,
);
