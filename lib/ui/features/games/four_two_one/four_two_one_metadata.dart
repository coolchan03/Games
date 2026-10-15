import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'four_two_one_screen.dart';

final fourTwoOneMetadata = GameMetadata(
  id: 'four_two_one', category: 'BOARD',
  icon: Icons.casino_outlined, color: DesignSystem.gamePurple,
  builder: (_) => const FourTwoOneScreen(),
  titleGetter: (_) => '421',
  subtitleGetter: (_) => 'Three dice, hold and reroll, 21 tokens to pass',
);
