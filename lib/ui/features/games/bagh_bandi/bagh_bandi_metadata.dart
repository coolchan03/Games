import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'bagh_bandi_screen.dart';

final baghBandiMetadata = GameMetadata(
  id: 'bagh_bandi',
  category: 'BOARD',
  icon: Icons.pets_outlined,
  color: DesignSystem.gameOrange,
  builder: (_) => const BaghBandiScreen(),
  titleGetter: (_) => 'Bagh Bandi',
  subtitleGetter: (_) => 'Bengal: two tigers vs four stacked herds of goats',
  popularity: Popularity.default_,
);
