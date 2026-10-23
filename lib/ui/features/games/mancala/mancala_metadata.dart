import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'mancala_screen.dart';

final mancalaMetadata = GameMetadata(
  id: 'mancala',
  category: 'BOARD',
  icon: Icons.grain_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const MancalaScreen(),
  titleGetter: (context) => 'Mancala',
  subtitleGetter: (context) =>
      'Kalah with local multiplayer and three AI levels',
  popularity: Popularity.high,
);
