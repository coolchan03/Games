# Games: 20-level coverage audit

Updated: 2026-10-20

The catalog contains 370 game screens. The question is not whether the game
can restart: **a level-based game needs at least 20 genuinely distinct,
playable, testable levels**. Every level must be completable, progression should
scale where reasonable, and offline progress should survive reopening the app.
Board/card games, reflex drills, and infinite-score games may instead use
repeatable rounds, AI difficulties, and meaningful variations.

## Verified / in-progress contracts

| Game | Minimum | Mechanism | Evidence |
| --- | ---: | --- | --- |
| Detective Casebook | 20 | 12 authored cases + 8 fixed-seed, solver-checked generated mysteries | casebook_engine.dart, twenty_level_campaign_test.dart |
| Nonogram | 20 | deterministic puzzles; unique-solution search; levels 1-20 grow from 5x5 to 9x9 | nonogram_engine.dart, twenty_level_campaign_test.dart |
| Sokoban | unbounded candidate | indexed seed, Easy/Medium/Hard | MUST still verify first 20 maps are distinct, solvable, and responsive |

The two 20-level implementations still require passing CI in the release
candidate before they can be considered delivered. The existing board game
catalog does not automatically satisfy this milestone.

The full 370-row inventory is in **LEVEL_COVERAGE_AUDIT_20261020.csv**.
Generate it again with:

`python tool/audit_level_progression.py --csv docs/LEVEL_COVERAGE_AUDIT_20261020.csv`

`--strict` deliberately fails until the catalog has been completely reviewed
and either the 20-level standard is verified or a justified non-level-based
classification is documented. A "level" string in source code is only a clue,
not proof of 20 levels.

## Next priority

1. Inspect all logic, deduction, maze and solitaire puzzle engines for actual
   level counts and repeated levels, beginning with Minesweeper, maze variants,
   Sudoku, Akari, Kakuro, Word Search, and the Simon Tatham puzzles.
2. For finite games, build at least 20 genuinely different puzzles with level
   selection, safe win state and persistence. For random generators, test a
   stable sample of at least 20 seeds and prove validity and uniqueness where
   relevant.
3. Classify competitive board/card games separately as replayable, with
   meaningful local opponents, match variations and difficulty settings.
4. Add end-to-end phone and Android interaction checks, including offline
   reopening, progress retention, difficulty progression and UI accessibility.

Do not turn the preliminary 58 "level" keyword hits into a claim of verified
coverage. Manual and engine-level examination remains required for 368 games.
