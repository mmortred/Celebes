CELEBES — WINDOW + USERNAME UPDATE

Full project: import Celebes-ui-arena-hud/project.godot in Godot.

WINDOW:
- 1280x720 design viewport, resizable window, keep aspect ratio.
- Maximize/restore using the normal Windows title bar.
- Godot embedded game view can also be popped out via the Game panel.

USERNAME:
- Main Menu > OPTIONS > PLAYER PROFILE > Username > Save Username.
- The lobby host broadcasts names when a player joins or the host renames themselves.
- Username is saved locally in user://player_profile.cfg.
- If running two instances, each instance can set a different in-memory name, but both share
  the same user:// save file on the same computer; the last saved name persists next launch.
- Existing connected clients should rejoin to change their displayed name.

IMPORTANT:
- This build is based on Celebes-overall-host-join-fix.zip. If you made changes afterward,
  back them up and apply the included changed files to your newer project instead.
- The game was not run inside Godot here; test HOST/JOIN and UI after import.
- Window resizing does not extend Arena artwork or tilemaps beyond their authored bounds.
