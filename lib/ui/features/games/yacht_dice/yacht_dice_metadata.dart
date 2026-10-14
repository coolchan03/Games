import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'yacht_dice_screen.dart';

final yachtDiceMetadata = GameMetadata(
  id: 'yacht_dice',
  category: 'BOARD',
  icon: Icons.casino_rounded,
  color: DesignSystem.gameOrange,
  builder: (context) => const YachtDiceScreen(),
  titleGetter: (context) => 'Yacht Dice',
  subtitleGetter: (context) => 'Roll, hold and score — 1-4 players or computer',
  popularity: Popularity.high,
);
