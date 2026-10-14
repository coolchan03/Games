import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'peg_solitaire_screen.dart';

final pegSolitaireMetadata = GameMetadata(
  id: 'peg_solitaire',
  category: 'LOGIC',
  icon: Icons.adjust_rounded,
  color: DesignSystem.gameOrange,
  builder: (context) => const PegSolitaireScreen(),
  titleGetter: (context) => 'Peg Solitaire',
  subtitleGetter: (context) => 'Jump pegs until only one remains',
  popularity: Popularity.default_,
);
