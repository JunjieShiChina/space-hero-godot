# Menu Atlas Font Extension

## Context

The main menu gained a new display mode row (`WINDOW / MAX / FULL`) beside the existing
pixel-atlas menu items such as `NEW GAME`, `2K`, and `QUIT GAME`.

## Symptom

- The new display mode text initially used a normal font and visually broke consistency.
- After switching back to atlas-rendered sprites, the word shapes were still wrong because
  new character regions were guessed by hand and pointed at the wrong glyphs/color set.

## Root Cause

The menu already uses a sprite-atlas font, not a runtime text font. Adding new labels
requires exact atlas regions for the same blue uppercase glyph set used by the existing
menu items. Reusing approximate coordinates or pulling glyphs from another color row
causes obvious visual mismatches.

## Better Approach

- Reuse the same atlas-driven rendering path as the existing menu items.
- Derive new glyph regions from the source atlas and existing scene data instead of
  estimating coordinates manually.
- Validate every newly added label in the real game window, not only by reading code.

## Validation

- Ran the menu verification scene and saved a runtime screenshot:
  `tests/output/display_modes/main_menu_display_modes.png`
- Confirmed `MAX` uses the same blue pixel glyph style as `NEW GAME` and `QUIT GAME`.
- Ran the required smoke test.

## General Rule

When extending atlas-based UI typography, treat the atlas mapping as source data. Do not
mix in `Label` fonts for convenience, and do not guess atlas rectangles when the project
already contains authoritative glyph usage in scenes, generated migration data, or the
original source project.

## Related Files

- `scripts/game/menu.gd`
- `scenes/main_menu.tscn`
- `generated/unity_stage0_menu_data.gd`
- `assets/sprites/duat font corporal.png`
