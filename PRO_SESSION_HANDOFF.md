# PRO SESSION HANDOFF — Games

Date: 2026-10-14

## Repository / restrictions
- Repo: https://github.com/coolchan03/Games
- Local checkout: C:\Users\coolc\Games
- **ALL GitHub edits, commits and pushes MUST use @Tunnel to surface.** Do not write through the GitHub connector.
- Remote `origin` = coolchan03/Games. Always pass `-R coolchan03/Games` to GitHub CLI; the GitHub CLI may otherwise resolve upstream Puzzle.
- Flutter is NOT installed on the Surface. Use GitHub Actions for `flutter analyze`, `flutter test`, `flutter build web`. Do not install Android SDK/Flutter on the laptop without permission.
- GitHub Pages is ENABLED as of this handoff (GitHub API POST, build_type=workflow); new Pages workflow run 38595704495 was triggered. Verify at https://github.com/coolchan03/Games/actions/runs/38595704495.
- Intended public URL: https://coolchan03.github.io/Games/ ; do NOT claim it's live without verifying.

## Current delivered features
- Upstream Puzzle GPL-3.0 core ~304 games plus 8 added game modules.
- Connect Four, Tic-Tac-Toe, Blackjack, Reversi, Mancala, Checkers, Detective Casebook (3 cases), lightweight flat Mahjong Solitaire.
- Flutter analyzers/tests/web-build succeeded in recent CI; previous workflow failure was *only* Pages deploy because Pages was disabled.
- Source inventory at docs/GAME_SOURCE_MATRIX.md, comprehensive goals at PROJECT_GOALS.md, high-level roadmap at PROJECT_PLAN.md, licensing in THIRD_PARTY_SOURCES.md.
- App must remain one unified lightweight Flutter UI. Do not embed many separate runtimes.

## Next Pro session — execute, don't merely plan
1. Verify Pages deploy CI passes and URL actually serves the app.
2. Implement a substantial new batch of game engines and screens using already vetted FOSS sources:
   - Chess from z7workbench/minigames (MIT), or directly integrate a small pure Dart chess engine.
   - Layered Mahjong from edave64/ED-Mahjong (MIT code; verify individual art license).
   - Poker (Texas Hold'em and Five Card Draw) via common deck/rank evaluator from thlorenz/phe (MIT) / themez/texas-holdem-house (MIT), port to Dart.
   - More Detective Casebook: varied mystery templates, unique-solution verification, difficulty levels, notebook persistence.
   - Additional game families from docs/GAME_SOURCE_MATRIX.md. Reuse existing code instead of creating redundant code.
3. Shared visual system: game cards, buttons, board, cards, app themes; make compact, classic, colorful options while preserving original games.
4. Add tests for each engine including forced captures, end states, poker ties, saved state, and detective-case uniqueness.
5. Run GitHub Actions; inspect **actual workflow logs** for failure causes, fix and rerun. Don't silence analyzer or tests.
6. Push through Tunnel only. Report commit SHA, links, verified tests, unfinished items. Never claim full completion until every objective passes.

## Standard terminal patterns
- `Set-Location 'C:\Users\coolc\Games'; git status --short`
- `git add -A; git commit -m '...'; git push origin main`
- `gh workflow run games-web.yml -R coolchan03/Games --ref main`
- `gh run list -R coolchan03/Games --workflow games-web.yml --limit 5`
- `gh run view <id> -R coolchan03/Games --log-failed`

## Known limitation
A >350 game collection with consistent UI, complete offline support, and full Android manual QA is **not completed**. Work in verified batches with honest progress reporting, not an unsupported claim of finishing everything in a single response.
