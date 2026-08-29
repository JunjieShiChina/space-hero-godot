# Authored Canyon Playfield Over Single Background

## Context

Stage 4 started from a tall looping texture, `alien_planet_vertical_loop.png`. The
goal was to turn that into a new playable stage rather than another skybox-like
background.

## Symptom

Even after fixing the shader sampling so the texture looped correctly, the stage still
looked fake. The result read as "one background image stretched behind the HUD" instead
of a navigable combat space. On a 1920x1080 viewport, the source texture was too narrow
to cover the width without either obvious horizontal repetition or aspect distortion.

## Root Cause

A single scrolling background can establish mood, but it usually cannot define the
playfield by itself when the stage theme depends on walls, lanes, or route pressure.
The texture was only a far-background plate. Treating it as the complete map meant the
player saw no authored boundaries, no midground route shapes, and no foreground depth.

## Better Approach

When a stage is supposed to feel like a canyon, tunnel, trench, or corridor:

- Keep the tall loop texture as the far background only.
- Add authored midground geometry that defines the playable corridor.
- Add foreground occluders or overhangs only when they read as attached canyon
  structure and clearly improve depth or speed cues.
- Put damage/collision on dedicated environment hazard nodes, not on the background.
- Use reusable scrolling chunk scenes or chunk definitions so route changes can be
  staged intentionally instead of relying on one image.
- If decorative loose props or overhangs read as unrelated floating clutter instead of
  canyon structure, remove them and let the corridor silhouette carry the scene.
  Decorative detail should reinforce the lane shape or wall mass, not compete with it.
- If the art direction for a stage shifts to "map only", remove all generated support
  layers for that stage chunk uniformly: decorative props, edge glows, foreground
  occluders, and authored hazard visuals. Do not leave one leftover accent layer that
  reintroduces visual noise after the rest has been stripped.
- If that generated support all comes from one stage-specific controller scene, prefer
  removing the controller from the stage entry scene instead of disabling pieces across
  multiple helper methods. That keeps the result unambiguous and avoids half-disabled
  leftovers such as masks, hazards, or overlays.

For wide screens, prefer authored corridor geometry over aggressive horizontal tiling.
Mild repetition in background layers is acceptable; obvious repetition in the playable
space is not.

## Validation

Validate with a real game window and capture multiple frames:

- an open corridor frame
- a narrowed corridor frame
- a hazard frame
- a later motion frame confirming the chunk sequence scrolls cleanly

If the first visible chunk can damage the player immediately, reorder the initial chunk
sequence before calling the result acceptable.

## Related Files

- Background shader: `shaders/scrolling_background.gdshader`
- Background component: `scripts/effects/scrolling_background.gd`
- Stage 4 scene: `scenes/stage_4.tscn`
- Stage 4 canyon controller: `scripts/stage4/stage4_canyon_controller.gd`
- Stage 4 canyon chunk: `scripts/stage4/stage4_canyon_chunk.gd`
