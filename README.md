# Games

**Open-source, lightweight, unified tabletop and puzzle library** for Android and web.

Based on [Puzzle](https://github.com/sidhant947/Puzzle) (GPL-3.0). Preserves the original catalog and adds classic board/card games within the same Flutter app.

## Current status
- Imported upstream Puzzle code as base.
- Added Connect Four, Tic-Tac-Toe, Reversi and Mancala with local two-player and selectable computer difficulty.
- Added Blackjack with an offline dealer (virtual scores only).
- Added Detective Casebook with three original whodunit cases and a deduction notebook; logic engine checks unique solutions.
- Existing Puzzle Word Search, Crossword, Cryptogram, Einstein Riddle and other puzzles retained.
- Remaining board, card, Mahjong and detective titles are planned, not yet implemented. Build verification runs in GitHub Actions.

## Run
Use a compatible Flutter SDK:
```sh
flutter pub get
flutter run -d chrome
flutter build web --release --base-href /Games/
```

GitHub Actions is configured to test and build web; after Pages is enabled with GitHub Actions as its source, deployment is intended for https://coolchan03.github.io/Games/.

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for the roadmap and [THIRD_PARTY_SOURCES.md](THIRD_PARTY_SOURCES.md) for copied FOSS code, attribution and licenses.

## License
GPL-3.0. Original Puzzle copyright and notices retained. Third-party game source and asset license details must be recorded before integration.
