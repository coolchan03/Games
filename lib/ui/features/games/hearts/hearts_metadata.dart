import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'hearts_screen.dart';

final heartsMetadata = GameMetadata(
  id: 'hearts',
  category: 'CARD',
  icon: Icons.favorite_rounded,
  color: DesignSystem.gameRose,
  builder: (context) => const HeartsScreen(),
  titleGetter: (context) => 'Hearts',
  subtitleGetter: (context) => 'Classic trick-taking against three computer players',
  popularity: Popularity.high,
);
