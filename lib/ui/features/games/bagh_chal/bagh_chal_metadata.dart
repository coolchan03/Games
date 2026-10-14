import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'bagh_chal_screen.dart';

final baghChalMetadata = GameMetadata(
  id: 'bagh_chal',
  category: 'BOARD',
  icon: Icons.pets_rounded,
  color: DesignSystem.gameOrange,
  builder: (context) => const BaghChalScreen(),
  titleGetter: (context) => 'Bagh Chal',
  subtitleGetter: (context) => 'Four tigers versus twenty goats',
  popularity: Popularity.default_,
);
