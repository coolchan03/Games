import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'oware_screen.dart';

final owareMetadata = GameMetadata(
  id: 'oware',
  category: 'BOARD',
  icon: Icons.grain_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const OwareScreen(),
  titleGetter: (context) => 'Oware',
  subtitleGetter: (context) => 'West African sowing game, Abapa rules',
  popularity: Popularity.default_,
);
