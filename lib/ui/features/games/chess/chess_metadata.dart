import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'chess_screen.dart';

final chessMetadata = GameMetadata(
  id: 'chess',
  category: 'BOARD',
  icon: Icons.castle_rounded,
  color: DesignSystem.gameBlue,
  builder: (context) => const ChessScreen(),
  titleGetter: (context) => 'Chess',
  subtitleGetter: (context) => 'Full rules, two players or computer',
  popularity: Popularity.high,
);
