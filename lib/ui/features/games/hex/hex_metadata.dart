import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'hex_screen.dart';

final hexMetadata = GameMetadata(
  id: 'hex',
  category: 'BOARD',
  icon: Icons.hexagon_outlined,
  color: DesignSystem.gameRed,
  builder: (context) => const HexScreen(),
  titleGetter: (context) => 'Hex',
  subtitleGetter: (context) => 'Connect your sides — no draws possible',
  popularity: Popularity.default_,
);
