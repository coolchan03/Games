# Games

**Open-source, lightweight, unified tabletop and puzzle library** for Android and web.

Based on [Puzzle](https://github.com/sidhant947/Puzzle) (GPL-3.0). Preserves the original catalog and adds classic board/card games within the same Flutter app.

## Current status
- Imported upstream Puzzle code as base.
- Added Connect Four, Tic-Tac-Toe, Reversi, Mancala and Checkers with local two-player and selectable computer difficulty.
- Added Blackjack with an offline dealer (virtual scores only).
- Added Detective Casebook with three original whodunit cases and a deduction notebook; logic engine checks unique solutions.
- Added compact 64-tile Mahjong Solitaire with solvable layouts, undo, hints and matching from ED-Mahjong's MIT code (traditional layered layouts remain planned).
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

See [PROJECT_GOALS.md](PROJECT_GOALS.md) for the complete product goals, [PROJECT_PLAN.md](PROJECT_PLAN.md) for development order, [docs/GAME_SOURCE_MATRIX.md](docs/GAME_SOURCE_MATRIX.md) for the source and game checklist, and [THIRD_PARTY_SOURCES.md](THIRD_PARTY_SOURCES.md) for attribution.

**Browser deployment:** the Flutter web build passed CI; to publish the site, enable Pages at [Repository Settings → Pages](https://github.com/coolchan03/Games/settings/pages) and choose **GitHub Actions** as source. GitHub returned 404 until Pages is enabled.

## License
GPL-3.0. Original Puzzle copyright and notices retained. Third-party game source and asset license details must be recorded before integration.
