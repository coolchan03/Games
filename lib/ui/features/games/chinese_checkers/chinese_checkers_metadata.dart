import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'chinese_checkers_screen.dart';

final chineseCheckersMetadata = GameMetadata(
  id: 'chinese_checkers',
  category: 'BOARD',
  icon: Icons.star_rounded,
  color: DesignSystem.gameRed,
  builder: (context) => const ChineseCheckersScreen(),
  titleGetter: (context) => 'Chinese Checkers',
  subtitleGetter: (context) => 'Hop across the star — 2, 3 or 6 players',
  popularity: Popularity.default_,
);
