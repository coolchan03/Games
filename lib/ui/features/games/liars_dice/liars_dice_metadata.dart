import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'liars_dice_screen.dart';

final liarsDiceMetadata = GameMetadata(
  id: 'liars_dice',
  category: 'BOARD',
  icon: Icons.casino_rounded,
  color: DesignSystem.gamePurple,
  builder: (context) => const LiarsDiceScreen(),
  titleGetter: (context) => "Liar's Dice",
  subtitleGetter: (context) => 'Bid, bluff and call liar — ones are wild',
  popularity: Popularity.default_,
);
