import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'cribbage_screen.dart';

final cribbageMetadata = GameMetadata(
  id: 'cribbage',
  category: 'CARD',
  icon: Icons.linear_scale_rounded,
  color: DesignSystem.gameEmerald,
  builder: (context) => const CribbageScreen(),
  titleGetter: (context) => 'Cribbage',
  subtitleGetter: (context) => 'Fifteen-two, fifteen-four… race to 121',
  popularity: Popularity.default_,
);
