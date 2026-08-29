# HUD Related Status Spacing

## Context

- The bottom HUD status row shows separate gameplay facts: weapon fire rate,
  friend count, and coin count.
- The coin icon and coin number in `scripts/ui/hud.gd` should read as one
  status group.
- Godot files involved: `scripts/ui/hud.gd` and `scenes/ui/battle_hud.tscn`.

## Symptom

- The coin icon sat visually closer to the friend count than to the coin number.
- The layout made the icon feel associated with the wrong status item, even
  though the code used separate constants for coin icon and coin count positions.

## Root Cause

- HUD items were placed with independent absolute coordinates.
- The design did not check the actual rendered extents of pixel-number text and
  scaled icons, so center-to-center values looked acceptable in code but the
  visual edge gaps were inverted.

## Better Approach

- Treat each icon/value pair as a visual group.
- Keep related icon/value edge spacing tighter than the spacing between
  unrelated groups.
- For fixed HUD rows, validate against rendered bounds, not only coordinate
  constants.
- Reuse this rule for coins, health, ammo, upgrades, lives, charges, cooldowns,
  and other compact status indicators.

## Validation

- Ran the smoke test:
  `/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd`
- Captured real runtime frames with Movie Maker:
  `tests/output/hud_coin_spacing/frame00000003.png`
- The captured frame shows the coin icon grouped with the coin number and
  separated from the friend count.

## Related Files

- `res://scripts/ui/hud.gd`
- `res://scenes/ui/battle_hud.tscn`
