import 'package:flutter/material.dart';
import '../../../../data/game_metadata.dart';
import '../../../../utils/design_system.dart';
import 'code_breaker_screen.dart';

final codeBreakerMetadata = GameMetadata(
  id: 'code_breaker',
  category: 'LOGIC',
  icon: Icons.password_rounded,
  color: DesignSystem.gameTeal,
  builder: (context) => const CodeBreakerScreen(),
  titleGetter: (context) => 'Code Breaker',
  subtitleGetter: (context) => 'Crack the colour code from hit and blow clues',
);
