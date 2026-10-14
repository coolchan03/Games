import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'spider_screen.dart';

final spiderMetadata = GameMetadata(
  id: 'spider',
  category: 'CARD',
  icon: Icons.pest_control_rounded,
  color: DesignSystem.gamePurple,
  builder: (context) => const SpiderScreen(),
  titleGetter: (context) => 'Spider Solitaire',
  subtitleGetter: (context) => 'Two decks, ten columns — 1, 2 or 4 suits',
  popularity: Popularity.default_,
);
