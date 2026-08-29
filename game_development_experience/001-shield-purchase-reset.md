# Single-Instance Refreshable Gameplay Effects

## Context

- Shield goods in stage gameplay should refresh the player's shield.
- Godot files involved: `scripts/game/stage.gd`, `scripts/entities/shield.gd`,
  and shield shop/pickup callers.
- This lesson applies to any gameplay effect that should have exactly one active
  owner-scoped instance and be refreshed by later pickups or purchases.

## Symptom

- Collecting or buying another shield while a shield was already active created an
  additional `ShieldBubble` node.
- Multiple active shield nodes overlapped and effectively stacked protection.
- The same failure mode can appear in other systems as duplicated buff nodes,
  repeated orbit helpers, duplicate warning overlays, stacked temporary weapons,
  multiple HUD indicators, or several active audio/visual loops for one state.

## Root Cause

- `Stage.spawn_shield()` instantiated a new shield every time.
- The stage did not keep ownership of the current shield instance or distinguish
  an active shield from a retired one.
- The implementation treated a refreshable state as a spawn-only event. That is
  risky whenever the design contract is "refresh or reset the existing effect"
  rather than "add another independent effect".

## Better Approach

- Keep a stage-local `ShieldBubble` reference.
- When a valid active shield exists, call a public `reset_health()` method instead
  of instancing another scene.
- If multiple active shields are found, keep one and queue the extras for removal.
- General rule: before spawning a persistent effect, decide whether it is
  stackable, replaceable, refreshable, or unique.
- For unique refreshable effects, give one clear owner responsibility for the
  active instance, expose a narrow refresh API such as `reset_health()`,
  `refresh_duration()`, or `apply_definition()`, and update shared state/UI from
  that API.
- When fixing similar systems, search for existing active nodes by stored
  reference, group, script type, or documented scene-tree branch before adding a
  new child.
- Add a focused regression test that proves repeated pickup/purchase leaves one
  active instance and refreshes the intended state.

## Validation

- Run the focused shield reset test:
  `/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/shield_reset_test.gd`
- Run the repository smoke test:
  `/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd`
- Both tests passed after the fix. Godot still reports the existing exit-time
  resource leak warning seen in the project baseline.

## Related Files

- `res://scripts/game/stage.gd`
- `res://scripts/entities/shield.gd`
- `res://test/shield_reset_test.gd`

## Reuse Checklist

- Does the gameplay design allow stacking, or should the later pickup refresh the
  existing state?
- Which node owns the active instance and its lifecycle?
- Is there a public method that refreshes the effect without rebuilding unrelated
  scene nodes?
- Does shared state such as HUD, `GameData`, audio, and collision reflect the
  refreshed instance?
- Does a regression test cover repeated acquisition?
