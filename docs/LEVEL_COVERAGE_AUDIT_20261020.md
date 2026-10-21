# Games: 20-level coverage audit

Updated: 2026-10-20

The catalog contains 370 game screens. A level-based game should have
**at least 20 distinct, playable, testable levels**. Levels should be
completable, meaningful, and increasing in challenge, with offline progression.
Competitive board/card games and reaction drills may instead qualify via
replayable rounds, local opponents, meaningful difficulty, or other variations.

## Campaigns covered by automated tests

| Game | Minimum | Mechanism | Test |
| --- | ---: | --- | --- |
| Detective Casebook | 20 | 12 authored + 8 fixed-seed, solver-checked mysteries | twenty_level_campaign_test.dart |
| Nonogram | 20 | 20 deterministic, unique-solution levels, 5x5 through 9x9 | twenty_level_campaign_test.dart |
| Minesweeper | 20 | 20 seeded 10x8 boards, nine through 28 mines, first-reveal protection | minesweeper_campaign_test.dart |
| Sokoban | 20 in each difficulty | Seeded maps for Easy, Medium and Hard; BFS push-solution validation for first 20 Easy levels and structural/distinctness checks for all 60 maps | sokoban_level_coverage_test.dart |
| Sudoku | 20 | Seeded 9x9 puzzles, target clues decrease from 44 to 28, uniqueness-checked; active entries saved | sudoku_level_campaign_test.dart |
| Classic Maze | 20 | Seeded connected 11x11-29x29 mazes; resumable player position, moves and breadcrumb trail | classic_maze_campaign_test.dart |

All six campaigns have numbered progression and offline selected-level
persistence; completion is stored for each campaign (and per difficulty in
Sokoban). Sudoku and Classic Maze also save unfinished active puzzle state. In Minesweeper the first clicked square changes the protected mine
layout, so the test compares levels using a common starting square. Its
generator ensures a safe opening but **does not guarantee no-guess solutions**.
Sokoban Hard and Medium puzzles have structural tests but do not yet have a
complete automated reachability proof for all 20 of those variations.

These source changes need to pass CI and physical device QA before release
certification. Do not conflate a source-code scan with gameplay testing.

## Full inventory

The full 370-row per-game inventory is maintained at
**docs/LEVEL_COVERAGE_AUDIT_20261020.csv**. Re-run with:

\`python tool/audit_level_progression.py --csv docs/LEVEL_COVERAGE_AUDIT_20261020.csv\`

\`--strict\` intentionally fails until every game has been examined and either
20 levels are verified or a documented replayable-game exemption is accepted.
A "level" keyword hit alone is not proof of coverage.

With these six candidate campaigns, 364 titles still require classification,
coverage testing or new progression. The highest priority unreviewed puzzle
engines include Akari, Kakuro, Word Search and other deduction puzzles.

## Follow-up tests and quality gates

1. Confirm Minesweeper 20-level gameplay on Android, including narrow phone
   landscape and portrait, tapping and long-pressing with Reveal/Flag.
2. Complete the remaining Sokoban Medium and Hard reachability audit without
   letting exhaustive solvers stall CI.
3. Validate the new Sudoku and Classic Maze campaigns in CI and on physical
   Android and offline PWA installs, including active puzzle save/resume.
4. Classify all competitive and free-play games as replayable rather than
   falsely numbering arbitrary matches.
5. Verify actual PWA offline install, reload, update and Android persistence.

No new games or external multiplayer services are needed for this phase.
