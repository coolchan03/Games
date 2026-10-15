# Games — Product Goals and Completion Criteria

## Vision
A single lightweight, free, offline-first games library for web browsers and Android.
A curated collection of board games, cards, word games, classic puzzles and detective
mysteries, powered by reusable open-source logic rather than embedded mini-apps.

## Non-negotiable product goals
1. **One cohesive design** — all games use the same navigation, surfaces, typography,
   input conventions, theme settings, dialog patterns, tile and card presentation.
   Individual games retain recognizable pieces and rules, but not separate design systems.
2. **Lightweight by default** — no bundled 3D engine or large AI models; reuse
   vector-drawn components, keep common UI shared and lazy-load optional advanced engines.
3. **Playable in a browser** — a responsive Flutter web version deployed on GitHub Pages,
   with keyboard, mouse and touchscreen controls, usable without sign-in.
4. **Android app** — same features and saves locally, with builds verified by CI.
5. **Offline play** — game logic is local. Offline caching is a specific testable PWA
   milestone; never label it complete merely because Flutter produces web assets.
6. **Human and AI opponents** — local pass-and-play for 2–6 people where game rules
   allow; multiple AI difficulties when meaningful.
7. **Genuine puzzles** — Crosswords, Word Search, Cryptograms, Sudoku, Nonograms,
   logic grids, Einstein riddles, deduction puzzles and murder-mystery cases.
   Generated deduction puzzles must have a solver-verified unique solution.
8. **Complete classics catalog** — all 50 referenced Family's Game Pack game types
   are desired, plus Mahjong Solitaire, Riichi Mahjong, Chess variants, Poker,
   Blackjack and additional card and traditional board games.
9. **Accessibility and usability** — controls large enough for phones; scalable text;
   color-independent cues; optional sound/haptics; hints and rules; auto-save/resume.
10. **Respect licensing** — preserve GPLv3 foundation and notices from all copied FOSS.
    Prefer directly reusable Dart logic; port from JavaScript/Kotlin/C# only as required.

## Target game categories
- Board and strategy: Chess, Checkers, Reversi, Mancala/Oware, Connect Four,
  Gomoku, Backgammon, Ludo, Dominoes, Chinese Checkers, Go, Shogi, Hex.
- Traditional family games: 50-game reference catalog including Battleship,
  Nine Men's Morris, Alquerque, Bagh Chal, Goose, Petits Chevaux, and more.
- Card and casino-style: Blackjack, Texas Hold'em, Five-Card Draw, Video Poker,
  Hearts, Spades, Bridge, Crazy Eights, Canasta, Rummy, solitaire variants.
  No actual gambling, money or real-money wagering.
- Word and brain puzzles: Word Search, Crossword, Cryptogram, Codewords,
  Anagram, Mastermind, Minesweeper, Sudoku, Nonogram, 2048, arithmetic puzzles.
- Detective and deduction: whodunits, theft cases, alibis, suspects, timelines,
  logic grids, contradictions and locked-room scenarios; hints without spoilers.
- Dice and casual: Yatzy, Liar's Dice, Shut the Box, 421, Air Hockey, Peg Solitaire.

## What is already implemented vs not
- Upstream Puzzle source with its original games is present (about 304 titles).
- 367 unique game IDs currently registered (original Puzzle and added titles). See
  README "Current status" and docs/GAME_SOURCE_MATRIX.md. Copied FOSS
  engines: minigames (Chess, Yacht Dice, Mancala, Hit & Blow scoring), CardsWithCats (Hearts,
  Spades, Oh Hell), bbackgammon (Backgammon), flutterflip (Reversi), ED-Mahjong + KMahjongg
  layouts, ludo_flutter route tables, and Simon Tatham's puzzles (Inertia and others).
- Shared GameScaffold / opponent picker / vector cards, dice and boards give the added games
  one look; they report wins to the existing streak/XP system.
- Verified locally on Flutter 3.47: `flutter analyze` (no errors or warnings), `flutter test`
  (all suites), `flutter build web --release`; release build loaded in headless Chromium.
- Web build serves CanvasKit from the site and bundles a symbol font, so card suits and chess
  pieces render offline. A full PWA service-worker/offline audit is still open.
- **Not complete:** manual Android device QA; full unified redesign of the ~304 original
  screens; remaining Family's Game Pack titles (Bagh Bandi, Nain Jaune,
  Passe-Trappe); Riichi Mahjong; Bridge;
  saved-game persistence for the added games.

## Completion gates for each new game
1. License and source provenance documented before copying code.
2. Actual rules and win/lose/draw conditions tested, including edge cases.
3. Game accessible through the main catalog and global design components.
4. Local 2-player / AI selection tested where applicable; difficulty has an effect.
5. Mobile portrait and browser layouts verified; no unexpected downloads.
6. CI analyzer, automated tests and web build pass.
7. Manual browser + Android checks documented separately.

## Priorities for next work batches (updated after phone testing)
1. **Complete the short remaining game list, then freeze the catalog.** Add only
   missing high-value families: 421, Petits Chevaux, Bagh Bandi, Nain Jaune,
   Passe-Trappe, Bridge, Riichi Mahjong, Shogi, Shisen-Sho, Canasta and a few
   worthwhile variants. Prefer polish to inflating the total count.
2. **Phone-first interaction:** robust large targets, responsive long-press,
   piece drag, hold, swipe and drop where sensible, plus a clearly labeled
   tap-to-select/tap-to-destination fallback. Test on an actual narrow phone.
3. **How to play for EVERY game:** consistent Objectives, Controls, Rules,
   Hints and Winning sections reachable before play and during play. Avoid
   empty guide screens and placeholder instructions; audit all registered IDs.
4. **Library discovery:** always-accessible search, quick category filters,
   useful sorting, favorites/recent games, readable compact card/list layouts.
5. **Single-device first:** solo, vs computer and pass-and-play. Online rooms
   and servers are out of scope. Local two-device multiplayer is optional
   only when simple and reliable, and cannot displace usability work.
6. Finish reliable autosave/resume, unified visual themes, PWA offline checks,
   accessibility, cross-browser QA and physical Android testing.
