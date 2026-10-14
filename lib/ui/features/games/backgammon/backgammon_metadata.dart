import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'backgammon_screen.dart';

final backgammonMetadata = GameMetadata(
  id: 'backgammon',
  category: 'BOARD',
  icon: Icons.casino_outlined,
  color: DesignSystem.gameOrange,
  builder: (context) => const BackgammonScreen(),
  titleGetter: (context) => 'Backgammon',
  subtitleGetter: (context) => 'Race and hit with gammons — vs computer or a friend',
  popularity: Popularity.high,
);
