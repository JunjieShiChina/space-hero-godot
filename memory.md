# Space Hero Migration Memory

## Ongoing migration prompt / 工作提示

- 视觉或画面效果改动必须启动 Godot 游戏实际运行验证，不能只靠代码推断或 headless smoke test。每次涉及主界面、关卡画面、动画、粒子、UI、层级、可见性、运动效果的修改，都要保存运行时截图；如果是运动效果，至少截图两帧或用运行时状态确认位置变化。
- 截图验证优先使用 `godot-remote-executor` / `godot-screenshot`。如果当前只有 editor executor、没有 game executor，可以从编辑器启动主场景，再用系统窗口截图兜底，但最终必须看真实游戏窗口画面。
- 不要什么都通过脚本控制。Godot 迁移应优先使用 Godot 原生结构：静态布局放在节点树里，可复用对象创建独立 `.tscn` 场景，配置/数值适合时放到资源或常量表里；脚本主要负责行为、状态、输入、随机和运行时调度。
- 该用节点就用节点，该创建场景就创建场景。比如主菜单背景、标题、按钮、选择器、飞船、陨石模板等可见结构应尽量是场景节点；敌人、子弹、拾取物、护盾、Boss、HUD 组件等后续迁移应逐步拆成可复用场景，而不是长期保留在单个脚本里动态拼装。
- 遇到不清楚、不确定或容易凭感觉误判的实现点时，优先查资料再实现，不能靠猜。资料来源应优先覆盖官方文档/API、成熟项目或高质量社区案例，并在动手前明确当前项目适合采用哪种做法。
- 添加或重做视觉特效时，不能只看官方粒子文档；必须同时搜索别人做出的优秀案例、教程或开源实现，观察他们如何组合粒子、Shader、AnimationPlayer、Polygon2D/Line2D、材质、场景节点和资源参数，再选一个当前需求下效果最好且可维护的方案落地。不要在没有调研参考的情况下直接手写临时特效。
- 画面层级调整要截图确认。尤其是 `z_index`、CanvasItem 顺序、Control/Node2D 混排、透明度、缩放、分辨率迁移后的坐标，都要以运行截图为准。
- 修改后至少跑一次 smoke test：`/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd`。视觉类修改还必须补充运行截图验证。

## 2026-04-25 Current migration progress audit

Source Unity project inspected at `/data/space-hero/Space-Hero`; target Godot project inspected at `/data/space-hero/space-hero-godot`.

### Snapshot

- Godot project is now a Godot 4.6.2 project with `res://scenes/main_menu.tscn` as the main scene, autoloads `GameData`, `AudioBus`, and `SceneFlow`, 1920x1080 canvas setup, physics layers for player/enemy/player_bullet/enemy_bullet/pickup/shield, and the Hastur operation editor plugin enabled.
- Godot MCP `get_project_info` reports 7 scenes, 27 scripts, 239 assets, and 277 other files. Of the 27 scripts, 16 are app gameplay/UI/autoload scripts and 8 are the Hastur addon scripts.
- Unity source has 7 main game scenes under `Assets/Scenes`: `stage0`, `stage1`, `stage2`, `stage3`, `transition`, `GameOver`, and `thanks`. Godot has the matching 7 scene files: `main_menu`, `stage_1`, `stage_2`, `stage_3`, `transition`, `game_over`, and `thanks`.
- Unity source has 107 C# scripts total, about 66 root or shallow gameplay scripts, 122 prefabs, and 25 `.anim` or `.controller` files. Godot has no reusable entity `.tscn` scenes outside `scenes/`, no `.tres`/`.res` gameplay resources, and no converted Godot animation resources yet.
- Unity `Assets/Audio` and `Assets/Sprite` are copied into Godot with exact filename parity: 36 audio files and 88 sprite PNG files are present in both projects. The remaining asset gap is prefab, animation, material, shader, joystick, and JMO effect conversion rather than raw sprite/audio presence.
- Headless smoke test passes with `/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd`. It still prints exit-time resource leak warnings, but no scene load or script error.

### Migrated or mostly migrated

- Main menu has the strongest parity. `scenes/main_menu.tscn` is a real node tree using source atlas glyphs, stars, red nebula, rocks, hero ship, wingmen, selector, `select.wav`, and `gamestart.wav`; `scripts/game/menu.gd` drives selection, flashing, start delay, wingman orbit, rock drift, and star twinkle.
- Core run state is represented by `autoload/game_data.gd`: coins, current stage, player health, bullet slots, current bullet index, friend count, and statistics. This maps the main intent of Unity `Data.cs`.
- Scene flow is present through `autoload/scene_flow.gd` and covers new game, stages, transition, game over, main menu, and thanks/end flow.
- Audio lookup and pooled playback exist in `autoload/audio_bus.gd`, with keys for menu/stage/boss/game-over/success, core bullet sounds, hit/explosion/pickup/coin/warning/shield/shop sounds, and settlement/pass-style sounds.
- Stage timing data in `scripts/game/stage.gd` now matches the known Unity `EnemyPlaneManager` timing values for boss time, warning delay, ship/ep2/rotation/meteor/small-boss delays, and probabilities: stage 1 boss at 120s; stages 2 and 3 boss at 180s; boss appears 6s after warning.
- Regular spawns stop after warning, matching Unity's coroutine stop behavior. Rotation enemies spawn once as a pair, and small boss spawns once after its configured delay.
- Core playable loop exists: player can move, shoot, switch bullets, collect coins/HP, buy bullet/friend/shield goods, fight enemies/bosses, clear stages, die to game over, and reach the thanks/statistics screen.

### Partially migrated

- `scripts/entities/player.gd` covers movement, mouse drag, weapon switching, shooting, and friend plane followers, but Unity touch-specific behavior, mobile UI controls, exact camera-world clamp conversion, and victory shoot-stop behavior are not fully matched.
- `scripts/entities/bullet.gd` contains all Unity bullet type names and intervals from `BulletManager.cs`, including `Bullet1`, `Bullet2`, `BulletArrow`, `BulletMissile`, `BulletLaser`, `BulletFire`, `BulletYue`, `Bullet3`, and `FollowBullet`. Damage, speeds, sprites, lifetimes, laser persistence, missile explosion, homing details, and pooling remain approximate.
- `scripts/entities/enemy.gd` covers ship, ep2, rotation_ep, meteor_enemy, meteor, and small_boss as one compressed class. It approximates Unity movement and shooting but does not preserve prefab-specific components, serialized health/collider values, animations, or exact Rigidbody2D velocity ranges.
- `scripts/entities/boss.gd` is a single compressed `BossShip` for all three bosses. It approximates boss 1 sweeps, boss 2 random movement/circle/laser, and boss 3 follow/missile/scatter behavior, but it is not a faithful port of `BOSSController.cs`, `Boss2AI.cs`, and `BOSS3AI.cs`.
- `scripts/entities/combat_body.gd` covers health, hit flash, death, stats, simple burst particles, and contact damage. It lacks Unity damage number display, invincibility handling, death animator controller behavior, boss explosion hooks, and exact object lifecycle/pool behavior.
- Drop logic is still not parity: Unity `Health.cs` uses coin drop probability `0.4` and HP drop probability `0.02`; Godot still uses `coin_drop_chance = 0.35` and `hp_drop_chance = 0.03`.
- `scripts/entities/shield.gd` reflects enemy bullets and follows the player, but Unity `Shield.cs` also damages enemies or players on shield contact. Current Godot shield does not connect its own `area_entered`, so enemy/body contact behavior is incomplete.
- HUD/shop are functional but text/procedural. Unity `SystemUIController.cs`, `NumberDisplay.cs`, bullet-slot icons, cursor movement, coin jump animation, warning art, boss/health bars, pause panel, and mobile switch button are not visually ported.
- `transition`, `game_over`, and `thanks` scenes exist and function, but they are simplified script-built screens rather than converted Unity scene layouts and animations.

### Not migrated yet

- No reusable Godot entity scenes/resources exist for player, enemies, bosses, bullets, pickups, shield, products, HUD widgets, or effects. Most gameplay is still created procedurally.
- Unity prefabs are not converted. This includes 122 `.prefab` files across gameplay, JMO effects, excluded music samples, and joystick assets.
- Unity animations/controllers are not converted. Missing Godot equivalents include coin animations, meteor animation, boom/explosion, missile animation/explosion, bullet fire/yue/follow bullet, boss animation, and number/effect animations.
- Unity `GameObjectPool.cs` is not ported. Godot currently creates bullets/effects directly and retires by hiding/disabling rather than reusing pooled objects.
- Unity laser and shield shader/material assets under `Assets/Laser` and `Assets/Shield` are not ported to Godot shader/material resources.
- Joystick/mobile package behavior is not ported. Godot currently relies on keyboard/mouse style input plus basic actions.
- JMO/Cartoon FX prefab effects are not ported; Godot uses simple CPUParticles2D burst placeholders.
- Unity scene serialized layout data has only been extracted for `stage0` menu (`generated/unity_stage0_menu.json` and `generated/unity_stage0_menu_data.gd`). Stage 1/2/3, GameOver, transition, and thanks scene object layouts still need extraction or manual reconstruction.

### Practical progress read

- Asset file copy progress for core sprites/audio: complete for `Assets/Sprite` and `Assets/Audio`.
- Scene coverage: all 7 high-level scenes exist, but only main menu is close to visual parity; gameplay/end scenes are mostly functional placeholders.
- Gameplay system coverage: playable vertical slice exists, with stage timing parity partly applied, but entity/prefab/animation/resource parity is still early.
- Best next migration slice: convert gameplay data into resources or constants from Unity serialized values, then split bullets/enemies/bosses into reusable scenes/resources before rebuilding HUD/shop visuals.

### Current validation

- Smoke command: `/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd`
- Result: `SMOKE TEST PASS`
- Residual issue: Godot prints exit-time `ObjectDB instances leaked` and `2 resources still in use` warnings during the smoke test.
