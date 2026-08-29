# Grounded Launch Enemy State Split

## Context

Stage 4 needed a new enemy that starts parked on the map, stays invulnerable while it
reads as part of the terrain, then lifts off inside the camera view and only becomes a
normal combat target after the launch finishes.

## Symptom

If the enemy is implemented as an ordinary flying ship from frame one, the player reads
it as a standard spawn instead of a parked map object. If it keeps its combat collision
active while grounded, player bullets can hit it before the launch fantasy starts. If
the launch is only a scale tween with no supporting cues, the lift-off feels fake.

## Root Cause

This kind of enemy is really two presentation states with different gameplay contracts:

- grounded map prop
- airborne combat ship

Trying to fake both states with one always-active combat configuration causes visual and
mechanical leakage between them.

## Better Approach

For enemies that begin attached to the environment and then launch into combat:

- Use a dedicated scene/script instead of forcing the behavior into a generic enemy path.
- Treat grounded and airborne as separate runtime states with an explicit transition.
- While grounded, move with the stage/background illusion if needed so the enemy reads as
  attached to the map.
- Disable damage reception and combat collision until the launch completes.
- Use at least three cues for launch readability:
  scale growth,
  thruster ignition,
  ground interaction such as a shadow change, dust burst, or expanding ring.
- Only enable shooting and restore combat collision after the launch settles.

If the project already has a stage-matching enemy sprite, prefer reusing it over
generating a new one so the new behavior inherits the stage's established visual
language.

## Validation

Validate with a real game window and capture at least three frames:

- grounded / parked state
- mid-launch state
- airborne combat state

Also verify mechanically:

- grounded bullets do not damage the enemy
- airborne bullets do damage the enemy
- the enemy begins firing only after the launch transition

## Related Files

- Enemy scene: `scenes/entities/stage4_takeoff_enemy.tscn`
- Enemy script: `scripts/entities/stage4_takeoff_enemy.gd`
- Stage hookup: `scripts/game/stage.gd`
- Visual record scene: `scenes/tests/stage4_takeoff_enemy_record.tscn`
- Visual record script: `scripts/tests/stage4_takeoff_enemy_record.gd`
