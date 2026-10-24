# Puzzle Master

**Open-source, lightweight, unified tabletop and puzzle library** for Android and web.

Based on [Puzzle](https://github.com/sidhant947/Puzzle) (GPL-3.0). Preserves the original catalog and adds classic board/card games within the same Flutter app.

## Current status
- 370 unique registered game IDs in one catalogue, including the original Puzzle titles
  and additional board, card, dice, deduction, and puzzle games.
- **Board & strategy:** Chess, Checkers, Reversi, Connect Four, Tic-Tac-Toe, Go (9×9/13×13),
  Hex, Gomoku, Backgammon, Ludo, Nine Men's Morris, Alquerque, Bagh Chal, Neutron, Chinese
  Checkers, Mancala, Oware, Dots and Boxes, Battleship, Snakes and Ladders, Dominoes, Game of
  the Goose, Air Hockey.
- **Cards:** Hearts, Spades, Oh Hell, Texas Hold'em, Five Card Draw, King's Corner, Nain Jaune,
  Video Poker, Blackjack, Gin Rummy,
  Cribbage, Crazy Eights, Go Fish, War, and solitaires Klondike, FreeCell, Spider, Golf,
  Pyramid, Forty Thieves, Aces Up, Poker Squares. Virtual chips only — no real money.
- **Dice & casual:** Yacht Dice, Liar's Dice, Shut the Box, Memory Pairs.
- **Puzzles & deduction:** layered Mahjong Solitaire (8 KMahjongg layouts, always solvable),
  Detective Casebook (12 cases plus solver-verified daily/random cases), Sokoban (generated,
  solvable), Code Breaker, Peg Solitaire, Tower of Hanoi, Nim, and Inertia, Same Game, Black Box,
  Twiddle, Sixteen and Signpost from Simon Tatham's collection.
- Two-player pass-and-play and Easy/Medium/Hard computer opponents where meaningful; wins feed
  the app's existing streaks and XP.
- Engines are tested in `test/games/`; every added screen is smoke-tested at 360 dp width.
  GitHub Actions verifies `flutter analyze`, `flutter test`, and `flutter build web`.
  Manual Android-device testing and a comprehensive browser-offline audit remain open.
- See [docs/GAME_SOURCE_MATRIX.md](docs/GAME_SOURCE_MATRIX.md) for what came from where.

## Run
Use a compatible Flutter SDK:
```sh
flutter pub get
flutter run -d chrome
flutter build web --release --base-href /Games/
```

GitHub Actions is configured to test and build web; after Pages is enabled with GitHub Actions as its source, deployment is intended for https://coolchan03.github.io/Games/.

See [PROJECT_GOALS.md](PROJECT_GOALS.md) for the complete product goals, [PROJECT_PLAN.md](PROJECT_PLAN.md) for development order, [docs/GAME_SOURCE_MATRIX.md](docs/GAME_SOURCE_MATRIX.md) for the source and game checklist, and [THIRD_PARTY_SOURCES.md](THIRD_PARTY_SOURCES.md) for attribution.

**Browser deployment:** GitHub Pages is configured for Actions at https://coolchan03.github.io/Games/. A successful `main` deployment and a live-load check are separate release gates.

## License
GPL-3.0. Original Puzzle copyright and notices retained. Third-party game source and asset license details must be recorded before integration.
