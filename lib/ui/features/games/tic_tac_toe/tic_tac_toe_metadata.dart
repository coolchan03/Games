import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'tic_tac_toe_screen.dart';

final ticTacToeMetadata = GameMetadata(
  id: 'tic_tac_toe',
  category: 'BOARD',
  icon: Icons.close_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const TicTacToeScreen(),
  titleGetter: (context) => 'Tic-Tac-Toe',
  subtitleGetter: (context) =>
      'Two players or computer with three difficulties',
  popularity: Popularity.high,
);
