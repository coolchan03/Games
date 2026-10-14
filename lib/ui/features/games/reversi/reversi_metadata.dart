import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'reversi_screen.dart';

final reversiMetadata = GameMetadata(
  id: 'reversi',
  category: 'BOARD',
  icon: Icons.album_outlined,
  color: DesignSystem.gameGreen,
  builder: (context) => const ReversiScreen(),
  titleGetter: (context) => 'Reversi',
  subtitleGetter: (context) => 'Two-player strategy or offline computer opponent',
  popularity: Popularity.high,
);
