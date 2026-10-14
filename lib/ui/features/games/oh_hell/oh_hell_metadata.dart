import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'oh_hell_screen.dart';

final ohHellMetadata = GameMetadata(
  id: 'oh_hell',
  category: 'CARD',
  icon: Icons.psychology_alt_rounded,
  color: DesignSystem.gameViolet,
  builder: (context) => const OhHellScreen(),
  titleGetter: (context) => 'Oh Hell',
  subtitleGetter: (context) => 'Bid exactly the tricks you will win',
);
