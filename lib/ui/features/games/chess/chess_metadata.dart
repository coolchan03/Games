import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'chess_screen.dart';
final chessMetadata = GameMetadata(
  id: 'chess', category: 'BOARD', icon: Icons.castle_outlined,
  color: DesignSystem.gameTeal, builder: (_) => const ChessScreen(),
  titleGetter: (_) => 'Chess',
  subtitleGetter: (_) => 'Local two-player or three AI levels, with saved games',
  popularity: Popularity.high,
);
