# Shared Settings Subpage And Paused UI

## Context

The project needed:

- a `SETTINGS` entry on the main menu that opens a child settings page,
- the same settings choices available during gameplay,
- `ESC` to pause, open settings, and close the menu to resume.

## Symptom

Flattening display mode and resolution directly into the main menu worked for a quick test,
but it did not match the expected menu hierarchy and created pressure to duplicate logic for
main-menu settings and in-game pause settings.

## Root Cause

The display settings UI was treated as two loose menu rows instead of a reusable submenu.
That makes the information architecture weaker and usually leads to one-off pause menu logic.

## Better Approach

- Make `SETTINGS` a top-level main menu entry.
- Put display mode and resolution inside a reusable settings subpage scene.
- Reuse the same settings subpage inside gameplay through a paused overlay.
- For paused gameplay, follow Godot's standard pattern:
  - set `SceneTree.paused = true`,
  - keep the pause UI branch processing with `PROCESS_MODE_WHEN_PAUSED`,
  - let gameplay stay paused while the settings UI remains interactive.
- Keep `ESC` behavior aligned with menu depth:
  - on the top-level pause menu, `ESC` resumes gameplay,
  - inside the settings subpage, `ESC` goes back one level instead of skipping the hierarchy.

## Validation

- Main menu settings screenshot:
  `tests/output/settings/main_menu_settings.png`
- In-game paused settings screenshot:
  `tests/output/settings/pause_settings_overlay.png`
- Required smoke test passed.

## General Rule

When a game exposes the same settings from multiple entry points, implement one shared
settings surface and embed it where needed. Do not maintain separate copies of the same
navigation and setting logic for main menu and pause menu unless the UX intentionally differs.

For Godot pause flows, prefer a dedicated paused UI branch over making gameplay roots
`PROCESS_MODE_ALWAYS`.

## Related Files

- `scripts/ui/settings_menu.gd`
- `scenes/ui/settings_menu.tscn`
- `scripts/ui/pause_settings_overlay.gd`
- `scenes/ui/pause_settings_overlay.tscn`
- `scripts/game/menu.gd`
- `scripts/game/stage.gd`
