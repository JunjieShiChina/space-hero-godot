# Game Development Experience Navigation

This folder stores game development lessons learned while building Space Hero in Godot, including Unity-to-Godot migration, generated content, new gameplay, UI, visual effects, tools, and systems.

Before migration work or new game development work, review this file and any relevant linked experience files. After discovering a mistake, failed approach, validation issue, or reusable solution, add or update an experience file here.

## How To Use

- Use one Markdown file per substantial lesson.
- Prefer updating an existing related file instead of creating duplicates.
- Keep lessons concrete: context, symptom, root cause, better approach, validation method, and related files.
- Link related screenshots, scripts, scenes, source Unity files, and Godot files when useful.

## Experience Files

- `000-template.md`: Template for adding new game development lessons.
- `001-shield-purchase-reset.md`: General pattern for single-instance refreshable effects, using shield pickups as the concrete case.
- `002-hud-related-status-spacing.md`: HUD grouping rule for keeping related icon/value pairs closer than unrelated status groups.
- `003-unity-stage-data-alignment.md`: Checklist for aligning Unity stage scene data with Godot stage configs, resources, and runtime screenshots.
- `004-authored-collision-pivot-scaling.md`: Rule for preserving scene-authored collision alignment when runtime code rescales offset sprites.
- `005-homing-target-locking.md`: Rule for locking homing projectile targets once at
  launch instead of reacquiring after target loss.
- `006-laser-telegraph-particle-layering.md`: Pattern for building readable warning
  lines and laser beams from sprite/Line2D cores plus visible particle layers.
- `007-hastur-remote-executor-setup.md`: Checklist for bringing up Hastur editor/game
  executors and diagnosing auth, autoload, and paused-runtime failures.
- `008-window-scale-fullscreen-transitions.md`: Rule for keeping fullscreen or
  maximize transitions free of resize-feedback loops in root window scaling code.
- `009-public-reference-effect-fidelity.md`: Rule for building comparison scenes from
  public effect references without drifting into custom reinterpretations.
- `010-menu-atlas-font-extension.md`: Rule for extending atlas-rendered menu text from
  source glyph mappings instead of mixing fonts or guessing atlas coordinates.
- `011-shared-settings-subpage-and-paused-ui.md`: Rule for reusing one settings subpage
  across main menu and paused gameplay using Godot's paused UI branch pattern.
- `012-authored-canyon-playfield-over-single-background.md`: Rule for turning a tall
  looping background into an authored corridor stage instead of treating one image as
  the whole playfield.
- `013-grounded-launch-enemy-state-split.md`: Rule for enemies that start as grounded
  map props and only become combat targets after a visible launch transition.
