import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'connect_four_screen.dart';

final connectFourMetadata = GameMetadata(
  id: 'connect_four',
  category: 'BOARD',
  icon: Icons.grid_on_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const ConnectFourScreen(),
  titleGetter: (context) => 'Connect Four',
  subtitleGetter: (context) => 'Two players or computer with three difficulties',
  popularity: Popularity.high,
);
