import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'goose_game_screen.dart';

final gooseGameMetadata = GameMetadata(
  id: 'goose_game',
  category: 'BOARD',
  icon: Icons.flutter_dash,
  color: DesignSystem.gameAmber,
  builder: (context) => const GooseGameScreen(),
  titleGetter: (context) => 'Game of the Goose',
  subtitleGetter: (context) => 'The traditional 63-square race',
  popularity: Popularity.default_,
);
