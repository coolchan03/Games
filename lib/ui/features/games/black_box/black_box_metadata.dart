import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'black_box_screen.dart';

final blackBoxMetadata = GameMetadata(
  id: 'black_box',
  category: 'LOGIC',
  icon: Icons.highlight_alt_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const BlackBoxScreen(),
  titleGetter: (context) => 'Black Box',
  subtitleGetter: (context) => 'Fire lasers to deduce hidden balls',
  popularity: Popularity.default_,
);
