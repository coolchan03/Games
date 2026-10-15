import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'nain_jaune_screen.dart';

final nainJauneMetadata = GameMetadata(
  id: 'nain_jaune',
  category: 'CARD',
  icon: Icons.stars_rounded,
  color: DesignSystem.gameTeal,
  builder: (_) => const NainJauneScreen(),
  titleGetter: (_) => 'Nain Jaune',
  subtitleGetter: (_) => 'Yellow Dwarf: chip trays, ascending sequences and hidden hands',
  popularity: Popularity.default_,
);
