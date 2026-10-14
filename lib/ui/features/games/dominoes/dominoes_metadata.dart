import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'dominoes_screen.dart';

final dominoesMetadata = GameMetadata(
  id: 'dominoes',
  category: 'BOARD',
  icon: Icons.view_agenda_rounded,
  color: DesignSystem.gameEmerald,
  builder: (context) => const DominoesScreen(),
  titleGetter: (context) => 'Dominoes',
  subtitleGetter: (context) => 'Double-six draw game for 2-4 players',
  popularity: Popularity.default_,
);
