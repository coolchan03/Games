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

## Current delivered features (updated 2026-10-14, cloud session)
- Work from this session is on branch `ccr-2c9dfd0e-lym5o4` (not yet merged to main, so the
  Pages workflow has not deployed it).
- 361 catalogue entries: ~304 upstream Puzzle games + 57 added games (list in README and
  docs/GAME_SOURCE_MATRIX.md).
- Copied/ported FOSS: minigames (Chess, Yacht Dice, Hit & Blow scoring), CardsWithCats
  (Hearts, Spades, Oh Hell), bbackgammon (Backgammon), ludo_flutter (route tables),
  KMahjongg layouts via ED-Mahjong, Simon Tatham's puzzles (Inertia, Same Game, Black Box,
  Twiddle, Sixteen, Signpost). Attribution in THIRD_PARTY_SOURCES.md and THIRD_PARTY_LICENSES/.
- Layered Mahjong (8 layouts, solvable deals/shuffles); Detective Casebook has 12 curated cases
  plus generated daily/random cases, all solver-verified unique, with an easy/hard mode.
- Shared kit: lib/ui/features/games/common/ (GameScaffold, OpponentPicker, CardView/HandView,
  trick table, solitaire piles, poker evaluator, DieFace, Disc). Added games report wins to the
  existing streak/XP system.
- Web fixes: CanvasKit served locally (was fetched from gstatic), bundled GamesSymbols fallback
  font, catalogue titles fall back to each game's registered title.
- Verified locally with Flutter 3.47.7: `flutter analyze --no-fatal-infos` (no errors or
  warnings), full `flutter test`, `flutter build web --release --base-href /Games/`, and the
  build loaded in headless Chromium (Hearts and Texas Hold'em opened from the catalogue).
- Known: one upstream engine test (compound_connect) was flaky because of duplicate options; fixed.

## Next session
1. Merge the branch to main and confirm the Pages deployment serves the app.
2. Manual Android device QA of the added games (touch targets, layouts, performance of AI).
3. Remaining Family's Game Pack titles: Bagh Bandi, Petits Chevaux, Nain Jaune, King's Corner,
   421, Passe-Trappe, Goose game, Air Hockey (peeweesusername/airhockey, GPL-3.0).
4. Persist in-progress games for the added titles (Hive), PWA offline audit (service worker,
   Roboto fallback request).
5. Optional heavier ports: Riichi Mahjong (kobalab/Majiang, MIT), more Tatham puzzles
   (Galaxies, Map, Tracks), PySolFC solitaire variants.

## Standard terminal patterns
- `Set-Location 'C:\Users\coolc\Games'; git status --short`
- `git add -A; git commit -m '...'; git push origin main`
- `gh workflow run games-web.yml -R coolchan03/Games --ref main`
- `gh run list -R coolchan03/Games --workflow games-web.yml --limit 5`
- `gh run view <id> -R coolchan03/Games --log-failed`

## Known limitation
A >350 game collection with consistent UI, complete offline support, and full Android manual QA is **not completed**. Work in verified batches with honest progress reporting, not an unsupported claim of finishing everything in a single response.
