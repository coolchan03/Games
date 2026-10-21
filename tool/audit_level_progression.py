#!/usr/bin/env python3
"""Conservative 20-level audit of all Games screens.

This is a coverage inventory, NOT proof that games with a 'level' variable
offer 20 different playable puzzles. Only manually inspected, regression-
tested campaign contracts are called verified.
"""
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = ROOT / "lib" / "ui" / "features" / "games"
VERIFIED = {
    "detective_casebook": (
        "20", "12 authored + 8 fixed-seed solver-checked mysteries",
        GAMES / "detective_casebook" / "casebook_engine.dart",
        r"campaignCount\s*=\s*20",
    ),
    "nonogram": (
        "20", "20 deterministic, unique-solution puzzle levels, 5x5-9x9",
        GAMES / "nonogram" / "nonogram_engine.dart",
        r"campaignLevelCount\s*=\s*20",
    ),
    "minesweeper": (
        "20", "20 seeded 10x8 minefields with safe first reveal, 9-28 mines",
        GAMES / "minesweeper" / "minesweeper_engine.dart",
        r"campaignLevelCount\s*=\s*20",
    ),
    "sokoban": (
        "20", "20 seeded levels per difficulty; easy push-path BFS and all layouts tested",
        GAMES / "sokoban" / "sokoban_engine.dart",
        r"static SokobanLevel generate",
    ),
}


def audit():
    screens = sorted(GAMES.rglob("*_screen.dart"))
    names = [screen.parent.name for screen in screens]
    if len(names) != len(set(names)):
        raise RuntimeError("Two game screens share one directory name")
    rows = []
    for screen in screens:
        game = screen.parent.name
        src = screen.read_text(encoding="utf-8")
        level_words = bool(re.search(r"\blevel(?:Number|Index|Count|s)?\b|_level", src))
        next_level = bool(re.search(
            r"Next level|Next case|nextLevel|nextPuzzle|levelNumber\+\+", src,
            flags=re.IGNORECASE,
        ))
        difficulty = bool(re.search(r"\bdifficulty\b|Easy.*Medium.*Hard", src))
        if game in VERIFIED:
            count, detail, engine, pattern = VERIFIED[game]
            if not re.search(pattern, engine.read_text(encoding="utf-8")):
                raise RuntimeError(f"Verified level count missing for {game}")
            status = "verified_minimum_20_by_tests"
            levels = count
        else:
            status = "not_yet_reviewed"
            levels = "unknown"
            detail = "Needs manual classification as level-based or replayable, then a gameplay test"
        rows.append({
            "game_id": game,
            "status": status,
            "verified_playable_levels": levels,
            "level_text_seen": int(level_words),
            "next_level_text_seen": int(next_level),
            "difficulty_text_seen": int(difficulty),
            "notes": detail,
        })
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", type=Path, help="Write full, inspectable report")
    parser.add_argument("--strict", action="store_true",
                        help="Fail until EVERY screen has verified 20+ levels or a reviewed replayable exemption")
    options = parser.parse_args()
    rows = audit()
    verified = sum(r["status"] == "verified_minimum_20_by_tests" for r in rows)
    candidates = sum(r["status"] == "numbered_generator_needs_20_level_validation" for r in rows)
    unreviewed = sum(r["status"] == "not_yet_reviewed" for r in rows)
    if options.csv:
        target = options.csv if options.csv.is_absolute() else ROOT / options.csv
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("w", encoding="utf-8", newline="") as out:
            writer = csv.DictWriter(out, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        print(f"Report: {target}")
    print(f"Game screens: {len(rows)}")
    print(f"Verified level-based campaigns >=20: {verified}")
    print(f"Generator needing validation: {candidates}")
    print(f"Still unreviewed / not classified: {unreviewed}")
    print("Not certified as twenty levels: " + str(candidates + unreviewed))
    if options.strict and verified != len(rows):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
