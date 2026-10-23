# Games master completion tracker

Updated 2026-10-22. Machine-readable source: `docs/GAMES_MASTER_COMPLETION_TRACKER.csv` (370 unique game IDs).

## Current assessment

{'NOT_REVIEWED': 346, 'NEEDS_IMPLEMENTATION': 0, 'IMPLEMENTED_UNVERIFIED': 24, 'TEST_FAILED': 0, 'VERIFIED': 0, 'BLOCKED': 0}

The six legacy 20-level campaigns (Detective Casebook, Nonogram, Minesweeper, Sokoban, Sudoku, Classic Maze) have reported level coverage but are not yet certified end-to-end. Word Search has 40 fixed-seed themed levels covered by CI tests; its missing Windows screen was safely restored from the published source. The original 20-level audit now executes, and its recognized campaign list is updated in this batch. Browser and Android gameplay certification is still pending.

Six solitaire titles have web/Android CI-verified implementation changes on main at `fb47744`, including drag handling, dead-end messaging where applicable, and landscape improvements. Physical device testing remains pending. GitHub CI success does not equal every game being gameplay-verified.

## Next engineering work

1. Validate Word Search touch, resume and offline behavior on a real device; keep the restored local screen intact.
2. Certify the six existing 20-level campaigns, including saving, browser/mobile input, solution correctness and meaningful difficulty.
3. Build at least 20 validated levels for level-based games where missing. Next group: Einstein Riddle, Futoshiki, Hitori, Nurikabe, Slitherlink, Binary Puzzle, Cryptogram, Word Mastermind.
4. Classify all remaining games by actual mechanics, separating replayable games from campaign games.
5. Verify restart/help/offline/resume and touch controls across the catalog, then obtain Android device feedback and release.

## Certification states

`NOT_REVIEWED`, `NEEDS_IMPLEMENTATION`, `IMPLEMENTED_UNVERIFIED`, `TEST_FAILED`, `VERIFIED`, `BLOCKED`. Zero games are marked VERIFIED solely by source inspections or catalog registration. Each row tracks missing evidence explicitly rather than fabricating completion.

## Akari campaign ? candidate pending CI

20 distinct authored boards (5x5 to 7x7), offline progress, restart and level navigation, plus source tests are included on the Akari test branch. Independent Python puzzle solver checked exactly one solution per board. Flutter CI, browser/device gameplay, and final certification remain pending. All 370 game IDs retained.

## Campaign audit reconciliation

The conservative source audit now recognizes eight campaign contracts with 20 or more tested levels: the original six, Word Search (40), and Akari (20). This is NOT end-to-end browser/Android certification. The master tracker continues to mark all 23 initially reviewed titles IMPLEMENTED_UNVERIFIED until game-specific acceptance criteria pass.

## Kakuro ? 20-level candidate awaiting certification

Replaces three randomized 4x4 templates with 20 authored, deterministic, independently unique-solution-checked puzzles (4x4 through 7x7). Introduces starter digit protection, level selection, offline progress/active-state saving, replay, and phone-landscape layout. Flutter CI, device playtesting, and browser certification remain pending. Never mark VERIFIED solely on source presence.
