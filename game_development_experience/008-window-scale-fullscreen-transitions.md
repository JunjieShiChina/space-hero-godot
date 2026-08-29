# Window Scale Fullscreen Transitions

## Context

The project uses a `DisplaySettings` autoload to manage runtime viewport scaling and
 window size selection. The game supports a fixed logical design size with Godot's
 `Window.CONTENT_SCALE_MODE_VIEWPORT`, while the OS can still move the native window
 between windowed, maximized, and fullscreen modes.

## Symptom

Clicking the system fullscreen or maximize control could intermittently freeze the game
 during the enlarge transition. In the worst case, the desktop session also became
 unresponsive for a moment because the native window manager and the game kept fighting
 over the same transition.

## Root Cause

The project listened to `Window.size_changed` and used that callback to reapply root
 window scaling configuration every time the native window geometry changed. That is too
 aggressive for fullscreen transitions:

- On Linux and Windows, Godot fullscreen is implemented by resizing a borderless native
  window to the monitor size.
- The transition can emit multiple intermediate size changes.
- Rewriting root `content_scale_size` / stretch settings or window constraints from that
  callback creates a resize-feedback path right in the middle of the window-manager
  transition.

Godot already scales the root viewport automatically once `content_scale_size`,
 `content_scale_mode`, and `content_scale_aspect` are configured. Those settings do not
 need to be rewritten on every OS-driven resize.

## Better Approach

Split the responsibilities:

- Configure root viewport scaling once on startup and when the game's logical
  resolution preset actually changes.
- Keep `size_changed` handling lightweight. Use it only for mode-sensitive constraints
  such as `min_size`, or to restore the chosen windowed size after returning from
  fullscreen.
- Do not rewrite root content scale settings during fullscreen/maximize transitions.
- Clear or relax window-only constraints such as `min_size` while the window is not in
  plain windowed mode.
- If a Linux/X11 desktop build still shows renderer or window-manager instability during
  native maximize even after cleanup, disable native window resizing/maximize for the
  game and expose only in-game resolution/fullscreen controls.

As a rule: if the OS is currently choosing the native window geometry, treat that as a
 window-manager concern, not a cue to rebuild your scaling configuration.

## Validation

- Run the project and toggle the native window between windowed and fullscreen several
  times from the system controls.
- Confirm there is no freeze during the enlarge transition.
- Confirm returning to windowed mode still respects the saved logical resolution.
- Run the required smoke test to make sure startup and scene flow still pass.

## Related Files

- `autoload/display_settings.gd`
- `project.godot`
