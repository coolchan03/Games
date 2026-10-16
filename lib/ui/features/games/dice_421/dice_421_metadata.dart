import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'dice_421_screen.dart';

final dice421Metadata = GameMetadata(
  id: 'dice_421',
  category: 'BOARD',
  icon: Icons.casino_outlined,
  color: DesignSystem.gamePurple,
  builder: (_) => const Dice421Screen(),
  titleGetter: (_) => '421 (Dice)',
  subtitleGetter: (_) => 'Charge and discharge · same-device 2-4 or computer',
  popularity: Popularity.default_,
);
