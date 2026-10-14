import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'alquerque_screen.dart';

final alquerqueMetadata = GameMetadata(
  id: 'alquerque',
  category: 'BOARD',
  icon: Icons.blur_on_rounded,
  color: DesignSystem.gameTeal,
  builder: (context) => const AlquerqueScreen(),
  titleGetter: (context) => 'Alquerque',
  subtitleGetter: (context) => 'The ancient jumping game behind draughts',
  popularity: Popularity.default_,
);
