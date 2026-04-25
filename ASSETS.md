# Space Hero Asset Migration Manifest

## Already Present in Godot

- Sprites: player, friend plane, enemy ships, boss ships, bullets, missile, laser, coins, HP, goods, asteroids/meteors, backgrounds, font images, warning-related art.
- Audio: menu/stage/boss/game-over music, shoot sounds, bullet variants, hit, explosion, pickup, coin, warning, shield, settlement, pass-stage, success/failure.
- Font: `assets/font/STHUPO.TTF`.

## Unity Asset Groups to Audit

- `Assets\Sprite`: sprite sheets, animation clips/controllers, bullet/boss/coin/meteor animations.
- `Assets\Font`: bitmap/TMP font assets and number display visuals.
- `Assets\Laser`: laser materials/controllers/effects.
- `Assets\Shield`: shield material/shader visuals.
- `Assets\JMO Assets`: third-party cartoon effects; likely should be approximated with Godot particles unless exact parity is required.
- `Assets\Scenes`: scene object positions, serialized health values, shop products/prices, boss references, HUD layout.

## Required Godot Scene/Resource Outputs

- Bullet scenes/resources for all Unity bullet types.
- Enemy scenes/resources for ship, ep2, rotation ep, meteor enemy, meteor, small boss.
- Boss 1/2/3 scenes or strategy resources.
- Player and friend-plane scenes.
- Shield scene with visual flash and reflection collider.
- Pickup/product scenes for coins, HP, bullet goods, friend goods, shield goods.
- HUD scenes for coin number, health bar, boss bar, bullet slots, selector, warning, pause, touch switch.
- Transition, victory, game-over, thanks/settlement scenes with matching visual layout.

## Conversion Priorities

1. Gameplay-critical sprites and colliders.
2. Bullet and explosion animations.
3. HUD number/bullet slot art.
4. Boss and warning presentation.
5. Settlement/game-over/menu polish.
6. Optional third-party particle effect approximations.

