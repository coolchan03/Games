import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'ludo_screen.dart';

final ludoMetadata = GameMetadata(
  id: 'ludo',
  category: 'BOARD',
  icon: Icons.emoji_events_rounded,
  color: DesignSystem.gameRed,
  builder: (context) => const LudoScreen(),
  titleGetter: (context) => 'Ludo',
  subtitleGetter: (context) => '2-4 players, pass-and-play or computer',
  popularity: Popularity.high,
);
