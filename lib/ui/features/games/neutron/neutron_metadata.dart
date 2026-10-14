import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'neutron_screen.dart';

final neutronMetadata = GameMetadata(
  id: 'neutron',
  category: 'BOARD',
  icon: Icons.blur_circular_rounded,
  color: DesignSystem.gameIndigo,
  builder: (context) => const NeutronScreen(),
  titleGetter: (context) => 'Neutron',
  subtitleGetter: (context) => 'Slide the Neutron home — a modern classic',
  popularity: Popularity.default_,
);
