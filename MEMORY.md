# Space Hero Project Background

## Overview

- This is a Godot 4.6 project that migrates the Unity game Space Hero into Godot.
- The main scene is `res://scenes/main_menu.tscn`.
- Core autoloads are `GameData`, `AudioBus`, and `SceneFlow`.
- The project uses a 1920x1080 canvas setup and GL Compatibility rendering.

## Migration Goal

- Prefer faithful Unity-to-Godot migration when Unity behavior, visuals, timings, sprites, audio, or scene data can be verified.
- Keep gameplay and visuals consistent with the Unity source before making intentional Godot-specific improvements.
- Compare Unity and Godot sprites, audio, and referenced assets when migrating features.

## Current State

- All high-level scenes exist in Godot: main menu, stages 1-3, transition, game over, and thanks.
- Core playable loop exists: player movement, shooting, bullet switching, coins/HP, shop items, enemies, bosses, stage clear, game over, and final statistics.
- Main menu has the strongest visual parity and is built as a real Godot node tree.
- Many gameplay systems are still approximate and should be refined against Unity source data.
- Bullets, enemies, bosses, HUD/shop, effects, animations, pooling, mobile controls, and some scene layouts still need deeper parity work.

## Validation

- Smoke test command:

```sh
/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd
```

- Visual changes must be verified in the real Godot game window with runtime screenshots.
