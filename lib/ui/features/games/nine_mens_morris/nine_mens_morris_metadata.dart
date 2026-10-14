import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'nine_mens_morris_screen.dart';

final nineMensMorrisMetadata = GameMetadata(
  id: 'nine_mens_morris',
  category: 'BOARD',
  icon: Icons.blur_circular_rounded,
  color: DesignSystem.gameTeal,
  builder: (context) => const NineMensMorrisScreen(),
  titleGetter: (context) => "Nine Men's Morris",
  subtitleGetter: (context) => 'Form mills and capture — vs computer or a friend',
  popularity: Popularity.default_,
);
