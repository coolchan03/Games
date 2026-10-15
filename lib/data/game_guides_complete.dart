import 'game_guides.dart';
import 'game_guides_added.dart';

/// Complete, offline instructions for every registered game.
GameGuide? guideForGame(String gameId) =>
    gameGuides[gameId] ?? addedGameGuides[gameId];
