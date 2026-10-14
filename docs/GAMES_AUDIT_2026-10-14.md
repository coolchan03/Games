# Games implementation and audit — 2026-10-14

Scope: `coolchan03/Games`, branch `pro-classics-completion-20261014`.
Requirement authority: `PROJECT_GOALS.md`, `PRO_SESSION_HANDOFF.md`,
`docs/GAME_SOURCE_MATRIX.md`, and `THIRD_PARTY_SOURCES.md`.
All source edits and pushes were performed through Surface Tunnel.
No Flutter or Android SDK was installed on the Surface.

## Completed and verified this batch
- Added King's Corner: 2–4 local seats, casual head-to-head bot, private
  hands, saving/restoring, legal stack/corner moves, and round-end scoring.
- Fixed Five Card Draw restart discoverability with a persistent app-bar
  control; included its widget regression test.
- Added King’s Corner rule, save-integrity, AI/deck conservation and
  360-dp mobile widget tests; initially failed CI before implementation.
- `flutter analyze --no-fatal-infos`, the complete `flutter test` suite,
  and `flutter build web --release --base-href /Games/` succeeded in
  GitHub Actions **38654372095** at commit `bb1dcf5`.
- The Android arm64 test APK build succeeded in run **38654372096**.
  This is an APK build gate, not real device-play certification.
- `python tool/audit_catalog.py` checked all imported metadata
  definitions and reported **365 registered entries / 365 distinct IDs**.
  It is wired into CI to catch future catalog drift.
- No embedded external apps, engines or third-party graphical assets
  were added. New King’s Corner code uses the repository’s GPL-3.0 license.

## Previous regression evidence
- Prior audit branch run **38651961518** had 5,339 passing tests and one
  failure: Five Card Draw smoke test could not find its off-screen
  bottom action `New table`. A top-bar action now keeps restart visible.
- Test-first run **38653382697** failed as expected because the
  missing King’s Corner engine was not yet implemented.

## Confirmed work still required

These are tracked requirements, not claims that a feature is fully verified:
- Finish Family's Game Pack parity (Bagh Bandi, Petits Chevaux,
  Nain Jaune, 421 and Passe-Trappe), Bridge, Riichi Mahjong and variants.
- Add durable saves/resume to the added games still lacking it and
  harmonize all original Puzzle screens with the shared visual system.
- Test PWA offline caching with an actual network-disabled reload and
  restored saves. CanvasKit being local does not prove offline installation.
- Perform Android touch/rotation/resize/manual regression checks on hardware.
- Confirm Chrome, Firefox, Safari and Edge with keyboard and accessibility
  checks; successful automated widget tests do not replace cross-browser QA.
- Investigate any remaining game-specific rule edge cases in the original
  ~300 games; the complete test suite is not exhaustive rule certification.
- Verify GitHub Pages deploy on the main branch and HTTP-load the exact
  stamped revision before declaring the website published.
- Check app-level stats/XP integration for every new game, including King's
  Corner; some new screens use common game surfaces without reward hooks.

## Branch/release policy

Feature validation on a branch does not publish a Pages site. Android
CI APKs are test builds, signed with debug settings, not production
release-signing artifacts. Do not confuse catalog code integration with
manual device/browser validation.

The prior `pro-classics-audit-20261014` worktree had unrelated local
uncommitted changes and was deliberately left untouched. Reconcile those
changes through a later verified PR rather than overwriting them.
