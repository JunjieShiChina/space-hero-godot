# Space Hero Unity → Godot Migration Plan

## Current State

- Source Unity project: `E:\spaceherounity\Space-Hero`.
- Target Godot project: `E:\Space-Hero-Godot\space-hero`.
- Godot currently has a playable framework: menu, three stages, transition, game over, ending, basic player/enemy/boss/bullet/pickup/HUD/audio systems.
- The Godot version is not yet mechanically faithful to Unity: most scene composition, timings, enemy health, bullet behavior, UI animation, effects, object pooling, mobile controls, and settlement presentation are simplified or approximated.
- Godot executable is not on `PATH`, so command-line smoke tests cannot run until the editor/CLI path is configured.
- The target folder is not a Git repository, so migration checkpoints cannot be committed unless Git is initialized or the project is placed in a repo.

## Migration Principles

- Match Unity behavior first, then improve Godot architecture.
- Keep gameplay data centralized and editable instead of scattering constants through scripts.
- Prefer Godot-native scenes/resources over trying to mirror Unity prefabs one-to-one.
- Preserve the current Godot framework only where it helps; replace approximation with verified Unity parity.
- Use `godogen` skill workflow artifacts (`PLAN.md`, `STRUCTURE.md`, `MEMORY.md`, `ASSETS.md`) as resumable migration state.
- Use Godot editor/plugins only for repeatable conversion tasks: scene inspection/import, sprite slicing, animation assembly, and visual QA capture. Do not depend on a plugin for runtime gameplay logic.

## Risk Tasks

1. **Coordinate and scale parity**
   - Define a Unity-world-to-Godot-pixel conversion table.
   - Verify camera bounds, player clamp bounds, spawn ranges, movement speeds, and bullet speeds.
   - Acceptance: player, enemy, bullet, and pickup positions visually match Unity stage proportions.

2. **Collision semantics**
   - Rebuild collision layers/masks for player, enemies, player bullets, enemy bullets, pickups, shields, and boss lasers.
   - Verify shield reflection, enemy contact damage, bullet ownership switching, piercing laser, and pickup triggers.
   - Acceptance: no friendly-fire bugs, no missing collisions, no repeated deferred collision crashes.

3. **Bullet behavior parity**
   - Port Unity `ShootBullet`, `Bullet`, `FollowBullet`, `LaserController2`, and `BulletManager` behavior into Godot data/resources.
   - Include all bullet types: `Bullet1`, `Bullet2`, `BulletArrow`, `BulletMissile`, `BulletLaser`, `BulletFire`, `BulletYue`, `Bullet3`, `FollowBullet`, `EMPTY`.
   - Acceptance: intervals and fire patterns match Unity scripts and are reusable by player, friends, enemies, and bosses.
   - Current progress: enemy bullet intervals now use Unity `BulletManager` values for migrated enemy types; rotation enemies use `BulletYue` at `0.2s`; regular ship/ep2/small boss use `Bullet2` at `2.0s`.

4. **Stage timing parity** — in progress
   - Replace current approximate `stage.gd` configs with Unity scene values.
   - Stage 1 Unity values: ship delay `0`, ship probability `0.8`, ep2 delay `10`, ep2 probability `0.6`, rotation delay `60`, rotation probability `1`, meteor enemy probability `0.1`, small boss delay `0`, boss time `120`.
   - Stage 2 Unity values: ship delay `10`, ship probability `0.6`, ep2 delay `20`, ep2 probability `0.8`, rotation delay `60`, rotation probability `1`, meteor enemy probability `0.2`, small boss delay `120`, boss time `180`.
   - Stage 3 Unity values: same spawn timing as stage 2 unless deeper scene inspection proves otherwise.
   - Acceptance: waves stop on warning, boss appears six seconds later, and music switches as in Unity.
   - Current progress: `scripts/game/stage.gd` now uses Unity boss timings, independent ship/ep2/meteor/meteor-enemy intervals, one-shot rotation pair spawn, one-shot small-boss spawn, and stops normal spawns once warning starts.
   - Remaining: validate spawn density visually against Unity and refine world-to-screen conversion for fixed-position spawns.
   - Verification: Godot 4.4 headless smoke test passes; Godot MCP can run and stop `stage_1.tscn` with no debug errors.

5. **Boss parity**
   - Split boss AI into separate Godot strategies matching Unity `BOSSController`, `Boss2AI`, and `BOSS3AI`.
   - Acceptance: boss 1 sweeps and fires 10-bullet arcs plus special burst; boss 2 moves to random targets, fires 18-bullet circles and lasers; boss 3 follows player x-position, rotates among scatter/missile/laser attacks.

## Main Build Tasks

1. **Project tooling**
   - Add a migration checklist command/script if useful.
   - Configure Godot CLI path for smoke tests.
   - Decide whether to initialize Git before large edits.

2. **Data model**
   - Convert `GameData` from hardcoded dictionaries into typed resources for bullets, enemies, stages, products, audio keys, and stats.
   - Preserve Unity counters: spaceships, ep2, rotation ep, meteor enemy, meteor, small boss, bosses, coin1/2/3.

3. **Asset manifest**
   - Audit Unity `Assets\Sprite`, `Assets\Font`, and audio assets against Godot `assets`.
   - Map missing animation controllers and sprite sheets to Godot `SpriteFrames`/`AnimationPlayer`.
   - Build reusable scenes for bullets, enemies, pickups, products, player, friend plane, shield, boss, effects, and HUD widgets.

4. **Player and friends**
   - Match Unity touch dragging, keyboard movement, camera bounds, tab weapon switching, and friend-plane activation.
   - Use the same bullet slot behavior: three slots, default bullet when slot is `EMPTY`, purchased bullet replaces next slot.

5. **Combat bodies**
   - Port Unity `Health` behavior: damage numbers, hit flash, invincibility, death animation, coin/hp drops, player game-over delay, boss explosion hook.
   - Port enemy movement and shooting: drift ships, chase EP2, rotation EP pair, meteor enemy, meteor, small boss.

6. **Bullets and pooling**
   - Add a Godot bullet pool equivalent to Unity `GameObjectPool` for high-frequency bullets.
   - Handle missile destruction, laser persistence, follow bullet target acquisition, shield reflection, out-of-bounds cleanup, and hit effects.

7. **Stage scenes**
   - Recreate Unity scene layouts for `stage1`, `stage2`, `stage3`, `GameOver`, `transition`, and `thanks`.
   - Convert procedural Godot scene construction into reusable editable `.tscn` nodes where parity matters.

8. **HUD and shop**
   - Port number display, coin jump animation, health/boss bars, bullet slot icons/cursor, friend count indicator, warning animation, pause screen, touch switch button, and shop goods.
   - Match purchase prices and product behavior from Unity scenes/prefabs.

9. **Audio and effects**
   - Map all Unity `AudioSource` usages to Godot buses and pooled players.
   - Recreate explosion, missile boom, shield flash, hit, pickup, warning, settlement, pass-stage, boss fight, and menu/game-over music behavior.

10. **Menus and settlement**
    - Port main menu cursor/button behavior, new game/init flow, quit behavior, game-over restart/quit flow, transition scene, victory animation, and final statistics display.
    - Current progress: main menu has been visually rebuilt against `1.mp4` reference with purple/red starfield, source-atlas orange title, source-atlas blue menu text, green ship cursor, drifting asteroids, and orbiting friend planes.

11. **Validation**
    - Run Godot smoke test once CLI path exists.
    - Capture screenshots/video for menu, each stage pre-boss, boss fights, game over, transition, and thanks.
    - Use visual QA after major gameplay/scene migrations.

## Immediate Next Implementation Order

1. Create data resources/constants for Unity parity values.
2. Replace `stage.gd` timing with Unity stage timing.
3. Refactor bullets into reusable bullet definitions and exact fire patterns.
4. Split boss logic by boss id to match Unity scripts.
5. Rebuild HUD/shop UI parity.
6. Add visual effects and settlement polish.
7. Run smoke/visual validation.
