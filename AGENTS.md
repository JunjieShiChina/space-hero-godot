# Space Hero Godot Agent Instructions

These instructions apply to the entire repository.

## Role

- Act as a senior Godot game development engineer.
- Make technical decisions with production-minded judgment for gameplay, scenes, resources, UI, effects, validation, and maintainability.
- Consider code elegance, extensibility, performance, maintainability, and clear ownership boundaries during development.
- When implementing migration or new content, prefer robust Godot-native solutions over temporary script-only approximations.

## Project Context

- This project is a Godot migration of the Unity game Space Hero.
- Prefer migration fidelity over quick approximations when Unity behavior, visuals, or data can be verified.
- For migration work, compare the Unity source project and Godot target project to confirm sprites, audio, and referenced assets are aligned before treating the work as complete.
- Keep static layout and reusable objects in Godot-native scene/resource structure where practical.
- New generated content should follow the same quality bar as migrated content: reusable, validated, performant, and consistent with the existing game.

## Godot Architecture

- Do not put every feature into scripts by default.
- Static layouts should live in scene node trees.
- Reusable visible/gameplay objects should be independent `.tscn` scenes when they are expected to be reused.
- Configuration and gameplay values should use resources, constants, or structured data when that is a better fit than hard-coded runtime construction.
- Scripts should focus on behavior, state, input, randomization, and runtime scheduling.
- Visible structures such as menu backgrounds, titles, buttons, selectors, ships, asteroid templates, enemies, bullets, pickups, shields, bosses, HUD components, and effects should gradually move toward reusable scenes/resources instead of remaining permanently as dynamic script-built nodes.

## Scene Organization

- Prefer a clear entry-point structure such as `Main -> World -> GUI`, or an equivalent project-local pattern that makes scene flow easy to follow.
- Organize the scene tree by ownership and lifecycle, not only by visual position.
- A child node should normally depend on the parent existing; if deleting the parent should not delete the child, place it elsewhere or use a sibling/manager relationship.
- Keep subsystems in clear branches of the scene tree so gameplay, UI, effects, audio, and debug helpers do not become tangled.
- Reusable scenes should be able to run or instantiate independently when practical.
- Avoid designs that require fragile special-case node moves during scene transitions; document and simplify any unavoidable exception.

## GDScript Style

- Follow the official Godot GDScript style guide unless existing local code strongly requires otherwise.
- Use one statement per line.
- Keep lines readable, preferably under 100 characters.
- Prefer `and`, `or`, and `not` over `&&`, `||`, and `!`.
- Declare local variables close to first use.
- Avoid member variables for values only used inside one method.
- Use static typing where it clarifies intent or catches mistakes.
- Organize scripts in a consistent order: signals, enums, constants, static variables, exports, regular variables, `@onready` variables, lifecycle callbacks, public methods, then private helpers.
- Keep comments sparse and useful; explain non-obvious decisions, not what the code mechanically does.

## Decoupling

- Avoid hard-coded parent assumptions, deep `get_parent()` chains, and brittle absolute node paths.
- Use signals when a node needs to announce something without knowing who handles it.
- Use groups for tag-like membership, broad notifications, or loose discovery across large scenes.
- Use explicitly exported or injected `NodePath`/node references when a dependency is real and local.
- Prefer small, focused APIs between systems instead of cross-layer direct field access.
- Runtime-instanced objects should not depend on a fixed parent structure unless that structure is part of their documented contract.

## Resources And Data

- Prefer custom `Resource` / `.tres` files for data-driven gameplay definitions such as weapons, bullets, enemies, bosses, stages, waves, drops, shop items, upgrades, and tuning values.
- Use resources when designers or future agents should edit values in the Inspector without changing code.
- Keep resource classes stable and typed so refactors do not require broad scene/script rewrites.
- Use scenes for behavior and node composition; use resources for reusable data, configuration, and lightweight logic.
- Avoid large hard-coded dictionaries or duplicated constants when a typed resource or shared data table would be clearer.

## Autoloads

- Use Autoloads for persistent cross-scene state, scene flow, static data, static helper functions, or broad systems that manage their own data.
- Do not create global manager singletons only for convenient access to ordinary scene-local behavior.
- Avoid Autoloads that invade or mutate many unrelated nodes' internal state.
- Prefer regular nodes, resources, signals, groups, or scene-local ownership when the system does not need global lifetime or global access.
- Never `free()` or `queue_free()` Autoload nodes at runtime.

## Performance

- Do not optimize by guesswork; identify the likely hotspot or validation target first.
- Consider performance when touching high-frequency systems such as bullets, particles, enemies, collisions, effects, UI updates, and spawning.
- Avoid unnecessary per-frame allocations, repeated node lookups, excessive signal churn, and avoidable scene-tree mutations.
- Use pooling or reuse for high-volume short-lived objects when creation/destruction becomes a real cost.
- Keep collision shapes, process callbacks, particle counts, shader work, and draw/material changes proportional to the gameplay need.
- Prefer simple, measurable improvements over complex optimizations that reduce clarity without proven benefit.

## Research Expectations

- When an implementation detail is unclear, uncertain, or likely to be guessed incorrectly, research before implementing.
- Prefer official documentation/API references, mature projects, or high-quality community examples.
- Before implementing a researched approach, state which approach fits this project and why.
- When the user's goal, acceptance criteria, visual target, gameplay behavior, or implementation boundary is unclear and cannot be safely inferred from project context or references, ask the user before implementing.
- For new or rebuilt visual effects, do not rely only on official particle documentation. Look at strong examples, tutorials, or open-source implementations and consider how they combine particles, shaders, `AnimationPlayer`, `Polygon2D`/`Line2D`, materials, scene nodes, and resource parameters.

## Game Development Experience Log

- Record game development mistakes, debugging lessons, and verified best practices in `game_development_experience/`.
- Use `game_development_experience/README.md` as the experience navigation file.
- Store each substantial lesson in its own Markdown file under `game_development_experience/`, similar to a lightweight skills library.
- Before implementing migration work, generated content, new gameplay, UI, visual effects, tools, or systems, review the navigation file and any relevant experience files.
- When a mistake, failed approach, validation issue, or reusable solution is discovered during migration or new development, add or update an experience file before finishing the task.
- When the user is dissatisfied with a generated effect or implementation and the work is adjusted to an acceptable result, summarize the feedback, failed attempt, final approach, and validation in the experience log.
- Each experience entry should capture the context, symptom, root cause, better approach, validation method, and related files.
- Prefer updating an existing relevant experience file over creating duplicate lessons.
- Keep experience files practical and reusable so future agents can avoid the same errors and choose the best implementation approach for both migrated and newly generated game content.

## Visual Validation

- Any visual or screen-effect change must be verified by running the actual Godot game.
- Do not rely only on code inspection or a headless smoke test for changes involving the main menu, stage visuals, animation, particles, UI, node layering, visibility, or movement.
- Save runtime screenshots for visual changes.
- For motion effects, capture at least two frames or confirm movement through runtime state.
- Prefer `godot-remote-executor` / `godot-screenshot` for screenshot validation.
- If only the editor executor is available, start the main scene from the editor and use a system window screenshot as a fallback.
- The final visual check must be based on the real game window.
- Confirm layering changes with screenshots, especially changes involving `z_index`, CanvasItem ordering, mixed `Control`/`Node2D` trees, transparency, scaling, and resolution-converted coordinates.

## Required Validation

- After changes, run the smoke test at least once:

```sh
/opt/godot/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script test/smoke_test.gd
```

- Visual changes also require runtime screenshot validation in addition to the smoke test.
