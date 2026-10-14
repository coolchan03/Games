import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'video_poker_screen.dart';

final videoPokerMetadata = GameMetadata(
  id: 'video_poker',
  category: 'CARD',
  icon: Icons.videogame_asset_rounded,
  color: DesignSystem.gameAmber,
  builder: (context) => const VideoPokerScreen(),
  titleGetter: (context) => 'Video Poker',
  subtitleGetter: (context) => 'Jacks or Better with optimal-hold advice',
  popularity: Popularity.default_,
);
