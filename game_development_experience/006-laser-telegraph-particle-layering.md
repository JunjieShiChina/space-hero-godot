# Laser Telegraph Particle Layering

## Context

Stage 2 small boss laser attacks need a clear non-damaging telegraph followed by a
damaging laser beam. The Unity source uses a visible `bosslaserready` sprite for the
warning phase, then enables a child laser after one second. The damaging laser uses a
LineRenderer shader for the beam body and a ParticleSystem for start VFX.

## Symptom

A pure thin warning line and low-visibility particle defaults made the attack read as a
debug aim ray instead of an authored combat effect. The damaging beam also lacked the
strong orange-red core and visible energy particles seen in the Unity laser setup.

## Root Cause

Particles were treated as the whole effect instead of as supporting energy detail.
Without a soft particle texture, Godot `GPUParticles2D` output is easy to miss or reads
as small hard pixels. The warning also skipped the migrated `bosslaser.png` art, even
though Unity used that asset for the telegraph sprite.

## Better Approach

Build laser-like attacks in layers:

- Use an authored sprite or `Line2D` as the readable combat silhouette.
- Add wider `Line2D` glow layers and a narrow hot core with additive blending.
- Animate the line material with `TIME`/`UV` in a CanvasItem shader to avoid a static
  rectangle.
- Use `GPUParticles2D` with a soft generated texture, short lifetime, zero gravity,
  local coordinates, and a warm color ramp for energy flecks.
- Keep the telegraph and damaging laser as separate phases so collision only starts
  when the attack activates.

For migrated content, inspect the original Unity prefab or scene before tuning colors
and timing. Match the broad composition first, then tune density and readability in the
real game window.

## Validation

Use a focused stage visual probe that places the boss and player, forces the laser
attack, captures one frame during the telegraph phase, then advances past the warning
delay and captures the active laser. Also assert that particles have a process material
and texture, because a missing particle texture can pass structural tests but fail
visually.

## Related Files

- Unity source: `/data/space-hero/Space-Hero/Assets/Boss2AI.cs`
- Unity source: `/data/space-hero/Space-Hero/Assets/Laser/LaserController2.cs`
- Godot warning: `scenes/components/boss_laser_warning.tscn`
- Godot warning script: `scripts/components/boss_laser_warning.gd`
- Godot laser scene: `scenes/entities/bullets/bullet_laser.tscn`
- Godot laser script: `scripts/entities/bullet.gd`
- Verification: `scripts/tests/stage2_alignment_verify.gd`
