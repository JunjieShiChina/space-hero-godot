# Space Hero Godot Migration Structure

## Existing Godot Structure

- `project.godot`: Godot 4.4 GL Compatibility project, main scene `res://scenes/main_menu.tscn`, autoloads `GameData`, `AudioBus`, `SceneFlow`.
- `autoload/game_data.gd`: run state, coin count, stage index, player health, bullet slots, friend plane count, statistics.
- `autoload/audio_bus.gd`: music/SFX lookup and pooled audio players.
- `autoload/scene_flow.gd`: main scene, stage, transition, game-over, thanks navigation.
- `scenes/*.tscn`: thin scene shells that attach scripts; most nodes are created procedurally in scripts.
- `scripts/game/stage.gd`: procedural stage construction, enemy/pickup spawning, boss spawning, stage clear.
- `scripts/entities/*.gd`: combat body, player, enemy, boss, bullet, pickup, shield.
- `scripts/ui/hud.gd`: procedural HUD.
- `test/smoke_test.gd`: loads and instantiates all main scenes.

## Unity Source Systems

- `Assets\Data.cs`: persistent run data, stage list/index, health, bullet slots, friend count, statistics.
- `Assets\BulletManager.cs`: maps `BulletType` to prefab, interval, audio, and pool name.
- `Assets\ShootBullet.cs`: all player/enemy bullet firing patterns and `BulletType`/`ShooterType` enums.
- `Assets\Bullet.cs`: bullet damage, trigger behavior, missile/explosion logic, pooling cleanup.
- `Assets\Health.cs`: damage, death, drops, hit flash, game-over delay, statistic recording.
- `Assets\PlaneController.cs`: player movement, drag/touch input, bounds, weapon switching.
- `Assets\SystemUIController.cs`: coins, purchase flow, bullet slot UI, friend planes, shield purchase.
- `Assets\EnemyPlaneManager.cs`: stage spawning, warning timing, boss activation, music switch.
- `Assets\BOSSController.cs`, `Assets\Boss2AI.cs`, `Assets\BOSS3AI.cs`: three boss behaviors.
- `Assets\EnemyAI1.cs`, `Assets\RotationEpShootController.cs`: special enemy AI and shooting.
- `Assets\Shield.cs`: bullet reflection and shield damage.
- `Assets\Goods.cs`, `Assets\Coin.cs`, `Assets\HpPickUp.cs`: pickup and product interactions.
- `Assets\Settlement.cs`, `Assets\VictoryAnimationController.cs`, `Assets\ShowController.cs`: transition/end presentation.

## Recommended Godot Runtime Architecture

- `autoload/GameData`: persistent state only; no gameplay constants.
- `autoload/SceneFlow`: scene transitions and stage progression only.
- `autoload/AudioBus`: music/SFX playback and pooling.
- `autoload/ObjectPool`: bullet/effect pooling equivalent to Unity `GameObjectPool`.
- `resources/bullets/*.tres`: bullet speed, damage, interval, texture, hit effect, pool policy, lifetime, pierce/homing/laser flags.
- `resources/enemies/*.tres`: health, contact damage, texture, collision radius, drop rates, movement AI, bullet pattern.
- `resources/stages/*.tres`: background, spawn timings/probabilities, boss id, shop inventory, boss timing.
- `resources/products/*.tres`: price, type, bullet reward/shield/friend behavior.
- `scenes/entities/*.tscn`: reusable `Player`, `Enemy`, `Boss`, `Bullet`, `Pickup`, `Shield`, `FriendPlane`.
- `scenes/ui/*.tscn`: reusable HUD, number display, bullet slot, shop item, pause panel, warning label, settlement row.
- `scripts/systems/*.gd`: stage director, bullet factory, damage/effects coordinator, input adapter.

## Unity-to-Godot Mapping

- `Data.cs` → `autoload/game_data.gd` plus stage/bullet/enemy resources.
- `BulletManager.cs` → bullet definition registry plus `ObjectPool`.
- `ShootBullet.cs` → `BulletPattern` helper or methods on shooter components.
- `Bullet.cs` → `scripts/entities/bullet.gd` with exact trigger and cleanup rules.
- `Health.cs` → `CombatBody` plus damage popup/effect services.
- `PlaneController.cs` → `PlayerShip` plus input adapter.
- `EnemyPlaneManager.cs` → `StageDirector` using stage resources.
- `SystemUIController.cs` → HUD/shop scenes and `GameData` signals.
- Boss scripts → `BossShip` strategy classes or separate `boss_1.gd`, `boss_2.gd`, `boss_3.gd`.
- Unity prefabs/scenes → Godot `.tscn` reusable scenes plus resource-backed definitions.

## Godot Plugins and Skills

- `godogen` skill is active for resumable planning and execution artifacts.
- No Godot `addons/` directory or installed plugin was detected in the target project.
- Recommended plugin/tool usage during migration:
  - Use Godot editor import dock for sprite sheet slicing and font/audio import verification.
  - Add a lightweight custom editor/import helper only if repeated scene or metadata conversion becomes manual and error-prone.
  - Use visual capture/QA after each large migration slice.
  - Avoid runtime dependency on editor-only conversion plugins.

