# Homing Target Locking

## Context

Homing bullets in Space Hero are fired frequently and should behave as individual
projectiles with their own target choice. The tracking point can still come from the
target collision bounds, but the target ownership belongs to the bullet instance.

## Symptom

A follow bullet could lose its current enemy and then steer toward another enemy later
in its lifetime. This made a single projectile appear to switch intent after launch.

## Root Cause

The homing update called the global target search every physics frame. That mixed two
separate responsibilities: choosing a target at fire time and steering toward the
chosen target while it remains valid.

## Better Approach

Lock the homing target once per bullet instance:

- Reset the locked target during `setup()`.
- Attempt target selection once after the bullet has its team, position, range, and tree.
- Store both the selected target and a flag that says the selection attempt already ran.
- During physics updates, steer only toward the stored target if it is still valid.
- If the stored target dies, leaves the tree, or is otherwise invalid, keep the current
  projectile velocity and do not search for another target.

Use this rule for any projectile where target identity is part of the firing decision.
Use repeated target search only for weapons explicitly designed to retarget.

When migrating an acquisition range from Unity, convert Unity world units through the
project's established design-unit mapping before tuning by feel. The follow bullet's
Unity `checkDistance` is 6 units, which maps to 648 Godot design pixels in this project.

## Validation

Add a regression that locks a follow bullet onto one enemy, spawns another valid enemy
nearby, invalidates the original target, and confirms the bullet velocity does not
change toward the fallback enemy. Also test the lock boundary with a target that is
outside the old range but inside the migrated range.

## Related Files

- `scripts/entities/bullet.gd`
- `scripts/tests/stage2_alignment_verify.gd`
