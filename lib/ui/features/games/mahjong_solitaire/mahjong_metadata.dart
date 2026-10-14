import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'mahjong_screen.dart';

final mahjongSolitaireMetadata = GameMetadata(
  id: 'mahjong_solitaire',
  category: 'LOGIC',
  icon: Icons.view_comfy_alt_rounded,
  color: DesignSystem.gameGreen,
  builder: (context) => const MahjongSolitaireScreen(),
  titleGetter: (context) => 'Mahjong Solitaire',
  subtitleGetter: (context) => 'Classic layered layouts, always solvable',
  popularity: Popularity.high,
);
