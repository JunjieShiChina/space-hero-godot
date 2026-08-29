# Unity Stage Data Alignment

## Context

Stage migration fidelity depends on more than the target Godot scene name. Unity stores
spawn timing, probabilities, prefab references, health values, sprite references, and
component tuning inside the `.unity` scene file and attached script components.

## Symptom

Godot stage 2 visually matched the Unity background and most spawn timings, but missed
Unity's regular meteor spawns. Its stage 2 boss also used a different boss sprite and
lower health than the serialized Unity stage 2 boss.

## Root Cause

The Godot stage config had already copied several values from Unity
`EnemyPlaneManager`, but the Unity scene's referenced prefabs and boss component data
were not fully cross-checked. Scene resource defaults and runtime `configure()` values
can also diverge if only one side is updated.

## Better Approach

When aligning a migrated stage, inspect these Unity sources together:

- The stage `.unity` file for manager values, active prefabs, sprite GUIDs, transform
  scale, health components, and attached AI scripts.
- The referenced Unity scripts for runtime spawn cadence and AI parameter meanings.
- The Godot stage config, reusable entity scenes, and any runtime `configure()` method
  that can override scene defaults.

Update both Godot scene resources and script-side configuration when both participate
in the runtime result.

When a migrated stage has stable ownership boundaries, put those stable objects in the
stage `.tscn` instead of relying on `_ensure_*` construction forever. Good candidates
are camera, background layers, HUD instances, player start markers, the player scene,
and scene-local systems such as shop drop managers. Keep random spawns, bullets,
pickups, boss warnings, and rewards script-instanced because their lifetime is driven
by gameplay state.

If `_ensure_*` helpers remain as compatibility fallbacks, make them configure existing
scene nodes as well as newly created nodes. Otherwise scene-authored nodes can silently
keep old default textures, speeds, or tuning values.

## Validation

Use a focused runtime verification scene for long stages instead of waiting for the full
timeline. Instantiate the real stage scene, place the relevant migrated entities in
visible positions, assert key resources and tuning values, and save a screenshot from
the actual rendered game window.

For stage 2, this confirmed:

- Regular meteor config: `meteor_delay = 0.0`, `meteor_prob = 0.15`.
- Boss2 sprite: `Spaceship_Boss 3.png`.
- Boss2 health: `2000`.
- SmallBoss sprite: `Spaceship_Boss 3.png`.
- SmallBoss movement: use Unity `Boss2AI` behavior, choosing random points inside the
  camera view and moving toward them at `moveSpeed = 5` Unity units per second.
  Do not replace this with a continuous drift or sine wave unless intentionally
  changing the design.
- SmallBoss laser: `Boss2AI` instantiates `bosslaserready`, whose root warning sprite
  is visible immediately. Its damage child starts inactive and `ShowSubObjectsDelayed`
  enables it after `delayTime = 1`, so the Godot attack must separate the warning
  phase from the damaging `BulletLaser`.
- Stage 2 scene-authored nodes: `BackgroundLayer`, `ScrollingBackground`,
  `Starfield`, `BackgroundAsteroids`, `Camera2D`, `PlayerStart`, `Player`,
  `BattleHud`, and `ShopDropManager`.

For stage 3, this also confirmed:

- The final boss sprite in Unity `stage3.unity` is `Spaceship_Boss 1.png`, not
  `Spaceship_Boss 3.png`.
- The stage 3 small boss still uses `Spaceship_Boss 3.png`.
- Unity stage 3 boss lasers are mounted as child objects on the boss root, so their
  visible beam position follows the boss transform while active. When migrating this
  pattern, keep the warning/laser anchored to the boss owner instead of spawning a
  world-static beam once and forgetting it.
- Stage 3 stable scene ownership should match the Stage 2 pattern: author
  `BackgroundLayer`, `ScrollingBackground`, `Starfield`, `BackgroundAsteroids`,
  `Camera2D`, `PlayerStart`, `Player`, `BattleHud`, and `ShopDropManager` directly in
  `stage_3.tscn` instead of relying on `_ensure_*` to build the whole scene at runtime.

## Related Files

- Unity source: `/data/space-hero/Space-Hero/Assets/Scenes/stage2.unity`
- Godot config: `scripts/game/stage.gd`
- Godot boss behavior: `scripts/entities/boss.gd`
- Godot scenes: `scenes/entities/boss_2.tscn`,
  `scenes/entities/enemy_small_boss.tscn`
- Verification: `scripts/tests/stage2_alignment_verify.gd`,
  `scenes/tests/stage2_alignment_verify.tscn`
