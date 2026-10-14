import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'blackjack_screen.dart';

final blackjackMetadata = GameMetadata(
  id: 'blackjack',
  category: 'CARD',
  icon: Icons.style_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const BlackjackScreen(),
  titleGetter: (context) => 'Blackjack',
  subtitleGetter: (context) => 'Six-deck shoe, double, split and strategy advice — virtual chips',
  popularity: Popularity.high,
);
