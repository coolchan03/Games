import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'shut_the_box_screen.dart';

final shutTheBoxMetadata = GameMetadata(
  id: 'shut_the_box',
  category: 'MATH',
  icon: Icons.inventory_2_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const ShutTheBoxScreen(),
  titleGetter: (context) => 'Shut the Box',
  subtitleGetter: (context) => 'Dice and tiles — shut them all',
  popularity: Popularity.default_,
);
