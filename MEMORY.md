# Space Hero Migration Memory

## Discoveries

- Godot target is Godot 4.4 format and currently uses procedural node creation for most gameplay/UI.
- Godot assets already include many Unity sprite/audio names, including bullets, bosses, backgrounds, coins, HP, warning, and music.
- Godot scenes are thin wrappers; scene parity will require rebuilding layouts or converting Unity scene/prefab metadata.
- Current Godot stage timings are much shorter than Unity and appear tuned for quick demo play, not parity.
- Unity `stage1` boss time is `120`; `stage2` and `stage3` boss time are `180`; Godot currently uses `55/65/75`.
- Unity `Health` has coin drop probability `0.4`, HP drop probability `0.02`; Godot currently uses `0.35` and `0.03`.
- Unity records boss counters initialized to `1`, while Godot initializes boss counters to `0`; verify intended settlement display before changing.
- Unity `EnemyPlaneManager` stops regular enemy coroutines at warning time; Godot currently keeps existing timer paths except it gates by stage state only after boss defeat.
- Unity rotation enemies spawn as a pair at fixed x positions after delay if probability passes; Godot currently spawns single random-position rotation enemies repeatedly.
- Unity small boss appears once after delay; Godot currently has a repeated small-boss probability after delay.
- Godot CLI is not available as `godot` on `PATH`, but `@coding-solo/godot-mcp` can find Godot at `E:\godot\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64.exe`.
- Target project folder is not a Git repository.
- Godot MCP was tested through a temporary stdio client. Available tools: `launch_editor`, `run_project`, `get_debug_output`, `stop_project`, `get_godot_version`, `list_projects`, `get_project_info`, `create_scene`, `add_node`, `load_sprite`, `export_mesh_library`, `save_scene`, `get_uid`, `update_project_uids`.
- MCP `get_godot_version` returned `4.4.stable.mono.official.4c311cbee`.
- MCP `get_project_info` recognized `E:/Space-Hero-Godot/space-hero` with `7` scenes, `17` scripts, `125` assets, and `148` other files.
- Godot headless validation command works with the explicit executable path: `E:\godot\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64.exe --headless --path . --script test\smoke_test.gd`.
- `test/smoke_test.gd` needed an explicit `Node` type on instantiated scenes for Godot 4.4 GDScript type inference.
- SceneTree smoke tests do not set `get_tree().current_scene`; runtime spawns now use a safe parent fallback to `get_tree().root`.
- Godot smoke test prints `SMOKE TEST PASS`; it still reports minor exit resource leaks from headless teardown, but no script errors after the safe-parent fix.
- Godot MCP `run_project` was tested on `res://scenes/stage_1.tscn`; `get_debug_output` returned no errors and `stop_project` stopped the run cleanly.
- Migrated enemy behavior slice: ship/ep2/small boss now use `Bullet2` intervals from Unity, rotation enemies use `BulletYue` at `0.2s`, and rotation firing follows local rotation instead of aiming at the player.
- Reference video `1.mp4` is readable after installing `opencv-python-headless`; it is about `7.07s` at `30 FPS` and shows the Unity main menu.
- Unity main menu reference details: dark purple starfield, large orange/red `SPACE HERO` title, blue `NEW GAME` and `QUIT GAME`, green ship cursor, lower-left protagonist ship, and two red friend planes orbiting around it.
- Godot main menu was visually migrated against `screenshots/video_ref/frame_000500.jpg` and verified with captures in `screenshots/menu_after_3/`.
- Godot MCP `run_project` was tested on `res://scenes/main_menu.tscn`; debug output had no errors.
- Main menu detail pass continued through `screenshots/menu_after_7/`: title/menu text now uses cropped glyphs from `assets/sprites/duat font corporal.png`, title is orange/yellow with red shadow from the source atlas, background includes a red nebula overlay, and layout was tuned against the reference frame.
- First implementation slice updated `scripts/game/stage.gd` to use Unity stage spawn timings and warning/boss timing. Regular enemy spawning now stops after warning, matching Unity `EnemyPlaneManager`.
- Rotation enemies now spawn once as a pair around converted Unity x positions `-1.5` and `1.5`; the current conversion is `screen_x = 640 + unity_x * 128` and still needs visual calibration.
- Small boss now spawns once after the configured delay. Stage 1 delay is `0`, matching the serialized Unity value found in `Assets\Scenes\stage1.unity`.

## Current Godot Approximations to Replace

- Bullet speeds/damage are guessed in `scripts/entities/bullet.gd`; Unity source mainly defines intervals in `BulletManager.cs`, while prefab values must be checked for damage/sprite/collider details.
- Boss behaviors in `scripts/entities/boss.gd` are compressed approximations of all three Unity boss scripts.
- Shop goods are simplified and use generic `goods.png`; Unity has UI/icon behavior through `SystemUIController`.
- HUD is text-based and procedural; Unity uses number display, cursor, bullet slot icons, bars, warning, and animations.
- Main menu/game-over/thanks are simplified text screens; Unity scenes contain richer sprite layouts and selectable buttons.
- Effects are mostly missing or represented by flashes only.

## Open Questions

- Should the target become a Git repo before large migration changes?
- Where is the preferred Godot executable path for local validation?
- Should the final parity target be exact Unity gameplay timings, or adjusted for shorter Godot test loops after parity is achieved?
- Should Unity third-party effects under `JMO Assets` be approximated with Godot particles or replaced with existing sprites/audio only?

## Validation Notes

- Existing smoke test: `test/smoke_test.gd`.
- Expected future command once Godot CLI is configured: `godot --headless --path . --script test/smoke_test.gd`.
- Visual validation should compare Unity and Godot screenshots for:
  - Main menu layout.
  - Player position/bounds.
  - Stage 1/2/3 spawn density before boss.
  - Warning timing and boss entrance.
  - Each boss attack pattern.
  - Game over and final settlement screens.

## 2026-04-24 Main menu Unity data usage
- `generated/unity_stage0_menu.json` is an extracted representation of `Assets/Scenes/stage0.unity`: GameObjects, Transforms, SpriteRenderers, sprite GUID/fileID mapping, atlas rects, `m_Size`, camera ortho size, and orbit behaviour fields.
- Added compact Godot constants at `generated/unity_stage0_menu_data.gd` from the extracted JSON.
- `scripts/game/menu.gd` now uses Unity-derived data for font/source paths, background path, selector path, button atlas rects/local letter spacing, hero/friend paths, and friend start angles.
- Directly using Unity title child data exposed one bad visual result: the last title `O` uses a large atlas rect (`duat font corporal_8`) and does not match the recording when mapped na?vely. The title therefore keeps the visually verified row-mapped atlas implementation; buttons remain data-driven.
- Latest verified screenshot: `screenshots/menu_after_11/frame00000001.png`.
- Pixel bbox comparison against `screenshots/video_ref/frame_002070.jpg`: reference title scaled to 1280x720 is about `(184, 131, 952, 99)`, current is `(184, 126, 952, 91)`; reference blue text scaled is about `(509, 321, 259, 112)`, current is `(503, 325, 264, 103)`.

## 2026-04-24 Main menu node scene conversion
- Converted `scenes/main_menu.tscn` from a single root `Control` into a real Godot node tree: `Background`, `Nebula`, `Stars`, `Rocks`, `Title`, `MenuItems/NewGame`, `MenuItems/QuitGame`, `Selector`, `Ships/HeroShip`, `Ships/Wingman1`, and `Ships/Wingman2`.
- Letter sprites are now real `Sprite2D` nodes using `AtlasTexture` subresources from `duat font corporal.png`; each letter has `centered = false` to match the old script-built layout.
- `scripts/game/menu.gd` no longer builds static visuals in `_ready`; it only controls input selection, selector movement, wingman orbit, rock drift, and scene transitions.
- Latest node-based screenshot: `screenshots/menu_nodes_5/frame00000001.png`.
- Smoke test passes after node conversion.

## 2026-04-24 Remote executor homepage alignment
- Used `godot-remote-executor` through Hastur broker `http://localhost:5302` with the connected editor executor to open and modify `res://scenes/main_menu.tscn` directly inside Godot.
- Remote changes saved via `PackedScene.pack()` and `ResourceSaver.save()`.
- Adjusted homepage node positions: `Title=(184,131)`, `MenuItems/NewGame=(514,320)`, `MenuItems/QuitGame=(509,389)`, `Ships/HeroShip=(180,588)`, `Selector=(467,339)`.
- Updated runtime selector offset in `scripts/game/menu.gd` to `x -47`, `y +19` so the selected cursor stays aligned during input.
- Latest screenshot: `screenshots/menu_remote_align_2/frame00000001.png`.
- Pixel bbox comparison against `screenshots/video_ref/frame_002070.jpg`: reference scaled title approx `(184,131,952,99)`, current `(184,131,951,91)`; reference scaled blue approx `(509,321,259,112)`, current `(509,321,264,110)`; reference scaled green approx `(452,321,35,33)`, current `(452,321,28,36)`.
- Smoke test passes on Godot 4.6.2.

## 2026-04-24 Main menu feedback fixes
- Removed extra color tint from selector and orbiting wingmen; they now use the source sprite colors.
- Corrected selector orientation for Godot coordinates by using `rotation = +90бу` in `scenes/main_menu.tscn`.
- Wingmen still orbit `Ships/HeroShip`, but their own `rotation` stays `0.0` so their nose remains facing forward instead of spinning 360бу.
- Added a shader-driven slow random twinkle effect to `Stars` in `scripts/game/menu.gd`.
- Changed rocks/asteroids from diagonal drifting to top-down falling: initial positions start above the screen, velocities are mostly positive Y, and respawn from above after leaving the bottom.
- Latest screenshot: `screenshots/menu_feedback_2/frame00000001.png`; smoke test passes on Godot 4.6.2.

## 2026-04-24 Main menu animation feedback fixes
- Used `godot-remote-executor` to reload `res://scenes/main_menu.tscn` in the connected Godot editor and verify script compilation.
- `scripts/game/menu.gd` now drives title flashing from `TITLE_BASE_COLOR` to yellow and back using accumulated game time, not wall-clock time.
- Selected menu item now slow-flashes while pointed at; pressing accept starts a fast flash for 0.55s before calling `SceneFlow.start_new_game()`.
- Wingmen are phase-spaced with `TAU / wingmen.size()`, so the two wingmen are evenly distributed and become exactly left/right when parallel with the hero ship.
- Star shader twinkle has stronger alpha/brightness variation.
- Latest animation capture: `screenshots/menu_anim_feedback_2/`; smoke test passes on Godot 4.6.2.

## 2026-04-24 Menu option sound and color correction
- Unity `stage0.unity` selector object has AudioSource `select.wav` (`e5f823...`); `SystemController.MoveCursor()` plays this when moving between options.
- Unity `NewGame` button AudioSource uses `gamestart.wav` (`a5beb2...`); `NewGameButtonFunc.execButtonFun()` plays it, blinks fast, waits `1.5s`, then switches scene.
- Copied Unity `Assets/Audio/gamestart.wav` into `assets/audio/gamestart.wav` and added `AudioBus` key `game_start`.
- Godot menu now plays `select.wav` only on up/down option movement and `gamestart.wav` on confirming New Game.
- Menu option flashing now preserves source sprite colors: RGB stays `(1,1,1)` and only alpha changes.
- Remote executor validated `main_menu.tscn`, `gamestart.wav`, `select.wav`, and `menu.gd`; smoke test passes.
