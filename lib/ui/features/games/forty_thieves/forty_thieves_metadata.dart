import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'forty_thieves_screen.dart';

final fortyThievesMetadata = GameMetadata(
  id: 'forty_thieves',
  category: 'CARD',
  icon: Icons.account_balance_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const FortyThievesScreen(),
  titleGetter: (context) => 'Forty Thieves',
  subtitleGetter: (context) => 'Challenging two-deck patience',
  popularity: Popularity.default_,
);
