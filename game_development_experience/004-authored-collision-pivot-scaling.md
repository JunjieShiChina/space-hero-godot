# Authored Collision Pivot Scaling

## Context

Reusable entity scenes often have carefully authored collision polygons in the editor.
Some sprites are not centered on the entity root; effects such as meteors can place the
sprite above the root while the collision polygon covers only the solid body.

## Symptom

Stage 2 meteors looked correct in the editor, but runtime bullet hits registered below
the visible meteor body.

## Root Cause

Runtime setup scaled the authored collision polygon around the entity root. The meteor
sprite has a non-zero local position, so scaling around the root moved the collision
away from the sprite. The meteor then applied a second visual scale after setup without
reapplying collision scaling.

## Better Approach

When preserving scene-authored collision for a scaled visual, scale authored collision
points around the sprite pivot, not around the parent origin:

- Store authored collision data before mutation.
- Compute the runtime scale from current sprite scale versus authored sprite scale.
- Transform each authored point as `sprite.position + (point - sprite.position) * scale`.
- If a subclass applies an extra visual scale after common setup, re-run collision
  configuration after that scale.
- When a long bullet enters an `Area2D`, do not use the bullet root as the hit feedback
  position. Ask the hit body for the closest point on its collision boundary and spawn
  sparks or damage numbers there.
- For non-piercing bullets, hide and retire the bullet in the same frame as the hit.
  Deferring retirement leaves the projectile sprite and trail visible for one frame,
  which reads as an incorrect hit location when many bullets overlap.
- Homing and target selection should use a target tracking point derived from active
  collision bounds, not the entity root. Offset-sprite enemies can have roots far away
  from their visible body.
- Death explosions and other entity-owned feedback effects should use the same
  collision-derived tracking point rather than the root. Otherwise offset-sprite
  enemies can die with the explosion centered below or beside the visible body.

This keeps editor-authored collision aligned for both centered sprites and sprites with
intentional local offsets, and keeps feedback attached to the thing being hit rather
than the center of an overlapping projectile.

## Validation

Add a focused runtime assertion that the collision bounds and computed hit point stay
inside the visible sprite bounds for offset-sprite entities. For visual changes, also
capture a real game screenshot with collision debugging enabled and a representative
projectile hit or death effect. For the Stage 2 meteor, verify that the explosion
node spawns at `tracking_position()` and save a runtime frame, for example
`tests/output/stage2_meteor_explosion/frame00000003.png`.

## Related Files

- `scripts/entities/combat_body.gd`
- `scripts/entities/bullet.gd`
- `scripts/entities/enemy.gd`
- `scenes/entities/meteor.tscn`
- `scripts/tests/stage2_alignment_verify.gd`
