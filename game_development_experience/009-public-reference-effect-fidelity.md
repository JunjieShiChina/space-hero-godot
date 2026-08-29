# Public Reference Effect Fidelity

## Context

A standalone laser showcase scene was built so multiple Godot 2D laser examples could
 be compared side by side. The goal was not just to present five attractive beams, but
 to let the user compare recognizable public references.

## Symptom

The first pass looked polished, but the user correctly pointed out that several beams
 did not really resemble the cited online examples. The scene had become "five custom
 beam styles inspired by references" instead of "five public cases reproduced for
 comparison."

## Root Cause

The implementation mixed together:

- publicly documented structural examples, such as GDQuest's `RayCast2D + Line2D +
  particles` laser,
- public shader examples from Godot Shaders,
- and original visual reinterpretations added during implementation.

That drift breaks the user's trust in a benchmark scene. Once the scene is labeled as a
 comparison against named cases, the user expects each row to map to a recognizable
 public reference, not a hybridized house style.

## Better Approach

When building a reference-comparison scene:

- Only use references whose visible result and implementation shape can be inspected
  publicly.
- For each row, identify the reference's defining structure first: for example
  `RayCast2D + Line2D + 3 particle systems`, a single `ColorRect`/`Sprite2D` shader
  strip, or a `Line2D` with a specific glow mask shader.
- Match the case name, node type, animation behavior, and shader family before tuning
  color or polish.
- Keep case-specific topology intact. A `Line2D + particles` beam should stay a
  `Line2D + particles` beam, while a public `canvas_item` shader strip should stay a
  shader-driven strip instead of being rebuilt out of the same shared line stack.
- If a source is paywalled or only summarized, do not present the row as a reproduction
  of that source. Label it clearly as an inspired variation instead, or replace it with
  a fully public case.

As a decision rule: benchmark scenes need fidelity to reference identity before they
 need variety.

## Validation

- Compare the resulting scene against the original public pages, not only against local
  screenshots.
- Verify that each row can be justified in one sentence with a concrete structure match,
  such as "this one uses a shader strip with two noise textures because the cited shader
  does."
- For showcase scenes, make retesting cheap: keep a dedicated scene path, let the user
  retrigger all rows with one key, and consider a slow auto-loop so visual comparison
  does not depend on one short burst.
- Save runtime screenshots from the final showcase and review them side by side with the
  source references.

## Related Files

- `scenes/tests/laser_effect_showcase.tscn`
- `scripts/tests/laser_effect_showcase.gd`
- `scripts/tests/laser_effect_demo_beam.gd`
