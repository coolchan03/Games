import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'go_fish_screen.dart';

final goFishMetadata = GameMetadata(
  id: 'go_fish',
  category: 'CARD',
  icon: Icons.set_meal_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const GoFishScreen(),
  titleGetter: (context) => 'Go Fish',
  subtitleGetter: (context) => 'Ask, fish and collect books of four',
  popularity: Popularity.default_,
);
