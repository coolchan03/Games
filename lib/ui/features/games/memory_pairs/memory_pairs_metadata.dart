import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'memory_pairs_screen.dart';

final memoryPairsMetadata = GameMetadata(
  id: 'memory_pairs',
  category: 'MEMORY',
  icon: Icons.style_rounded,
  color: DesignSystem.gamePink,
  builder: (context) => const MemoryPairsScreen(),
  titleGetter: (context) => 'Memory Pairs',
  subtitleGetter: (context) => 'Concentration — solo, friend or computer',
  popularity: Popularity.default_,
);
