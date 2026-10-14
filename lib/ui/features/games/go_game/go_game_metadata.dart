import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'go_game_screen.dart';

final goGameMetadata = GameMetadata(
  id: 'go_game',
  category: 'BOARD',
  icon: Icons.radio_button_checked_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const GoGameScreen(),
  titleGetter: (context) => 'Go',
  subtitleGetter: (context) => '9×9 and 13×13 with captures, ko and area scoring',
  popularity: Popularity.default_,
);
