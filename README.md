# Games

**Open-source, lightweight, unified tabletop and puzzle library** for Android and web.

Based on [Puzzle](https://github.com/sidhant947/Puzzle) (GPL-3.0). Preserves the original catalog and adds classic board/card games within the same Flutter app.

## Current status
- Imported upstream Puzzle code as base.
- Connect Four added with local two-player and three AI levels; Blackjack added with offline dealer play (build testing pending).
- Existing Puzzle Word Search, Crossword, Cryptogram, Einstein Riddle and other puzzles retained.
- Other board, card, Mahjong and deduction titles are planned, not yet implemented.

## Run
Use a compatible Flutter SDK:
```sh
flutter pub get
flutter run -d chrome
flutter build web --release --base-href /Games/
```

GitHub Actions is configured to test and build web; after Pages is enabled with GitHub Actions as its source, deployment is intended for https://coolchan03.github.io/Games/.

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for source candidates and implementation waves.

## License
GPL-3.0. Original Puzzle copyright and notices retained. Third-party game source and asset license details must be recorded before integration.
