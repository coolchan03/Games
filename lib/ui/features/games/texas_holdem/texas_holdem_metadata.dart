import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'texas_holdem_screen.dart';

final texasHoldemMetadata = GameMetadata(
  id: 'texas_holdem',
  category: 'CARD',
  icon: Icons.style_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const TexasHoldemScreen(),
  titleGetter: (context) => "Texas Hold'em",
  subtitleGetter: (context) => 'No-limit poker for virtual chips against three bots',
  popularity: Popularity.high,
);
