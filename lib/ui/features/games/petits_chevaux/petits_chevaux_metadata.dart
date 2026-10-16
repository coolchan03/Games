import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'petits_chevaux_screen.dart';

final petitsChevauxMetadata = GameMetadata(
  id: 'petits_chevaux', category: 'BOARD',
  icon: Icons.sports_score_outlined, color: DesignSystem.gameBlue,
  builder: (_) => const PetitsChevauxScreen(),
  titleGetter: (_) => 'Petits Chevaux',
  subtitleGetter: (_) => 'French horse-racing board game, 2-4 players',
);
