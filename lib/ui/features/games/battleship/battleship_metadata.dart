import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'battleship_screen.dart';

final battleshipMetadata = GameMetadata(
  id: 'battleship',
  category: 'BOARD',
  icon: Icons.directions_boat_rounded,
  color: DesignSystem.gameCyan,
  builder: (context) => const BattleshipScreen(),
  titleGetter: (context) => 'Battleship',
  subtitleGetter: (context) => 'Hunt the hidden fleet before it finds yours',
  popularity: Popularity.default_,
);
