import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'signpost_screen.dart';

final signpostMetadata = GameMetadata(
  id: 'signpost',
  category: 'LOGIC',
  icon: Icons.signpost_rounded,
  color: DesignSystem.gameOrange,
  builder: (context) => const SignpostScreen(),
  titleGetter: (context) => 'Signpost',
  subtitleGetter: (context) => 'Follow the arrows to number every square',
  popularity: Popularity.default_,
);
