import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'klondike_screen.dart';

final klondikeMetadata = GameMetadata(
  id: 'klondike',
  category: 'CARD',
  icon: Icons.view_column_rounded,
  color: DesignSystem.gameEmerald,
  builder: (context) => const KlondikeScreen(),
  titleGetter: (context) => 'Klondike Solitaire',
  subtitleGetter: (context) => 'The classic patience — draw one or three',
  popularity: Popularity.high,
);
