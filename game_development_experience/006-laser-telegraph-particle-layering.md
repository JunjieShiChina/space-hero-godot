# Laser Telegraph Particle Layering

## Context

Stage 2 laser attacks for both the small boss and larger bosses need a clear
non-damaging telegraph followed by a damaging laser beam. The Unity source uses a
visible `bosslaserready` sprite for the warning phase, then enables a child laser
after one second. The follow-up Godot work also needed to match the local public
reference showcase's first beam style: readable `Line2D` body first, particles second.

## Symptom

A pure thin warning line and low-visibility particle defaults made the attack read as a
debug aim ray instead of an authored combat effect. A later pass over-corrected by
leaning too much on gradients, width curves, and particles, which left the screen with
floating red specks while the beam body itself was hard to see. The damaging beam also
lacked the strong orange-red core and visible energy particles seen in the Unity laser
setup.

## Root Cause

Particles and material tricks were treated as the whole effect instead of as supporting
energy detail. Without a strong opaque `Line2D` body, the viewer reads only the
particle noise. Over-styling the line with gradients and curves can reduce readability
more than it helps. For long screen-spanning attacks, the first question is whether the
beam silhouette itself is instantly legible in motion. Another failure mode is solving
"beam should start in front of the ship" by moving the whole laser origin too far
forward; that detaches the attack from the boss body instead of creating a short
showcase-style firing gap. A related failure mode is leaving the damaging beam at its
full-screen fallback length even after it hits the player, which makes the visible
effect disagree with the collision.

## Better Approach

Build laser-like attacks in layers, but keep the beam body simple first:

- Use a plain opaque `Line2D` body for the telegraph and the active beam before adding
  any shader or gradient complexity.
- Keep a dedicated forward `start_distance` near the firing point so the beam begins a
  short distance in front of the ship nose, matching projectile showcase behavior
  without visually detaching the attack from the owner.
- When matching a showcase beam that visibly pushes outward from the muzzle, add a very
  short cast/growth time to the damaging beam instead of spawning the final full length
  on the first frame.
- Derive the warning/laser origin from the attacker's real forward support point
  (sprite bounds, collision polygon, or collision shape) plus a small padding value
  instead of guessing from the entity center.
- For the active laser, stack 2-4 `Line2D` layers with wider red glow outside and a
  bright narrow hot core inside, matching the local showcase's first GDQuest-style beam
  composition.
- Use `GPUParticles2D` with a soft generated texture only for muzzle, beam flecks, and
  end impact accents.
- Keep the telegraph and damaging laser as separate phases so collision only starts
  when the attack activates.
- For the damaging phase, raycast from the effective beam start and shrink the beam
  visuals and collision to the first hit point so the laser visibly ends on the struck
  target.
- When the effect must span the screen, validate that the line visibly starts from the
  firing anchor before tuning particle density.
- Scale width by attacker class. A small boss should not reuse the same beam thickness
  as a larger boss; tune width and muzzle radius so the weapon reads as attached to that
  specific enemy.

For migrated content, inspect the original Unity prefab or scene before tuning colors
and timing. Match the broad composition first, then tune density and readability in the
real game window.

## Validation

Use a focused stage visual probe that places the boss and player, forces the laser
attack, captures one frame during the telegraph phase, then advances past the warning
delay and captures the active laser. Validate both the small boss and the larger boss
variants because shared beam scenes can still be called from different origins. Also
assert that particles have a process material and texture, because a missing particle
texture can pass structural tests but fail visually. Add a targeted assertion that the
active beam endpoint matches the struck target's closest collision point instead of the
default full-screen endpoint. When validating beam screenshots, place the player under
one specific barrel and advance the laser one or two physics ticks after activation so
the saved frame shows the impact particles at the struck endpoint, not only the beam
body. Do not treat a headless run with the dummy renderer as screenshot validation:
`root.get_texture().get_image()` can be null there, so use a real game window run for
final visual proof and keep headless runs for logic assertions only.

## Related Files

- Unity source: `/data/space-hero/Space-Hero/Assets/Boss2AI.cs`
- Unity source: `/data/space-hero/Space-Hero/Assets/Laser/LaserController2.cs`
- Godot warning: `scenes/components/boss_laser_warning.tscn`
- Godot warning script: `scripts/components/boss_laser_warning.gd`
- Godot laser scene: `scenes/entities/bullets/bullet_laser.tscn`
- Godot laser script: `scripts/entities/bullet.gd`
- Godot stage 2 enemy script: `scripts/entities/enemy.gd`
- Godot boss script: `scripts/entities/boss.gd`
- Verification: `scripts/tests/stage2_alignment_verify.gd`
- Verification: `scripts/tests/boss_laser_warning_verify.gd`
