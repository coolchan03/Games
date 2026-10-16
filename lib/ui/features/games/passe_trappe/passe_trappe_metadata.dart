import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'passe_trappe_screen.dart';

final passeTrappeMetadata = GameMetadata(
  id: 'passe_trappe',
  category: 'BOARD',
  icon: Icons.sports_handball_outlined,
  color: DesignSystem.gameBlue,
  builder: (_) => const PasseTrappeScreen(),
  titleGetter: (_) => 'Passe-Trappe',
  subtitleGetter: (_) => 'Sling pucks through the gate — solo or same device',
  popularity: Popularity.default_,
);
