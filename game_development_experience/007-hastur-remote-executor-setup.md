# Hastur Remote Executor Setup

## Context

This project uses the Hastur Godot plugin and broker-server to run GDScript remotely
 against either the Godot editor or the running game. That path is needed for runtime
 inspection, visual validation, screenshots, and scene debugging without adding one-off
 debug code to gameplay scripts.

The concrete task here was to confirm `editor` execution first, then bring up a working
 `game` executor for the same project.

## Symptom

Several failure modes looked similar from the outside:

- Broker HTTP was reachable, but `/api/executors` returned `401 Unauthorized`.
- Only an `editor` executor appeared, even after starting the game from the editor.
- `game` execution requests timed out even after the game process existed.
- Some snippets that looked valid in normal GDScript failed to compile in remote
  execution mode.

## Root Cause

Remote execution depends on the whole chain being live, not just one piece:

- Broker access needs a valid Bearer token.
- `editor` execution only works after the Godot editor plugin connects to the broker.
- `game` execution also needs the `GameExecutor` autoload registered in
  `project.godot`.
- A running game can still be unreachable when the runtime is paused by the debugger.
- Remote snippet mode does not always provide the same implicit context as a normal node
  script, so calls like `get_tree()` can fail unless the execution environment exposes a
  node-like base.

## Better Approach

Treat Hastur setup as a staged bring-up and validate each stage separately:

- Confirm broker health first, then query `/api/executors` with the auth token.
- Verify `editor` executor before touching game runtime concerns.
- For `game` executor, register `GameExecutor` as an autoload pointing to
  `res://addons/hasturoperationgd/game_executor.gd`, then restart or relaunch the game.
- If the game process is running but remote execution times out, inspect whether the
  Godot debugger paused on an error. Resume the game and enable Ignore Error Breaks when
  remote automation is the priority.
- Keep remote probes conservative. In `game` execution, prefer
  `Engine.get_main_loop() as SceneTree` over assuming `get_tree()` is available.
- For screenshot validation of newly triggered VFX, do not capture the viewport in the
  same instant as the trigger call. Trigger first, then wait at least one or two
  rendered frames or a short delay before saving the image, otherwise the screenshot can
  contain the previous frame and make live effects look missing.

Use a short bring-up checklist:

1. Broker reachable and token accepted.
2. `editor` executor visible in `/api/executors`.
3. `GameExecutor` autoload present in `project.godot`.
4. Main scene running.
5. `game` executor visible in `/api/executors`.
6. A minimal script returns current scene name or FPS.

## Validation

Validate the chain in two passes:

- `editor` pass: execute a probe that reads the current edited scene through
  `executeContext.editor_plugin.get_editor_interface()`.
- `game` pass: execute a probe that reads the runtime scene from
  `Engine.get_main_loop() as SceneTree`.

Useful API checks:

- `GET /api/executors`
- `POST /api/execute`

Success criteria:

- Both `editor` and `game` executors are listed by the broker.
- `editor` execution returns project or edited-scene information.
- `game` execution returns runtime data such as current scene name or FPS.

## Related Files

- Project settings: `project.godot`
- Plugin runtime: `addons/hasturoperationgd/game_executor.gd`
- Skill reference: `/home/junjie/.codex/skills/godot-remote-executor/SKILL.md`
