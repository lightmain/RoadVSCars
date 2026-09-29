# Spec: Textured Road Surface

## Assumptions

1. `road_width` remains the full visual and physical width.
2. Grass and shoulders are visual regions only; they retain the same
   collision and vehicle handling as asphalt.
3. With the current 40-meter road, each outer grass strip is 5 meters and
   each shoulder is 1.5 meters.
4. The center marking is 9 meters painted followed by a 6-meter gap.
5. A procedural shader may provide the textured appearance without adding an
   external image dependency.

## Objective

Replace the flat alternating road colors with one continuous surface showing
asphalt, a dashed center line, shoulders, and grass. The pattern must remain
continuous across dynamically generated segments and the starting road.

## Tech Stack

- Godot 4.7 spatial shader
- GDScript `SurfaceTool` mesh generation
- GdUnit4 6.2.1

## Commands

```sh
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode \
  --add tests/driving/dynamic_road_test.gd

HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode --add tests

HOME="$PWD/.tmp-home" \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

## Project Structure

```text
Scenes/Levels/dynamic_road.gd       Continuous road-distance UV generation
Scenes/Levels/road_surface.gdshader Surface regions and dashed center line
Scenes/Levels/road_meterial.tres    Dynamic road shader material
Scenes/Levels/level.tscn            Starting-road material assignment
tests/driving/dynamic_road_test.gd  UV and material contract tests
```

## Code Style

```gdscript
static func segment_uvs(
	start_distance: float,
	end_distance: float
) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, start_distance),
		Vector2(1.0, start_distance),
		Vector2(1.0, end_distance),
	])
```

Use tabs, typed values, and distance values in meters. Keep visual calculations
out of vehicle control code.

## Testing Strategy

- Unit-test that adjacent road segments share the same longitudinal UV.
- Assert the 9-meter dash and 6-meter gap configuration.
- Instantiate the level and verify both starting and dynamic roads use the
  shader material.
- Verify the starting road visual width equals its collision width.
- Run the complete suite and a headless editor load.
- Run the game and inspect the road from the active camera.

## Boundaries

- Always: retain full-width collision and existing road path behavior.
- Ask first: introduce different friction, off-road penalties, or narrower
  collision for grass.
- Never: reset longitudinal UV per segment or generate a new material for
  every road segment.

## Success Criteria

1. The surface visibly contains grass, shoulders, asphalt, and a center line.
2. Center dashes are 9 meters long with 6-meter gaps.
3. Markings continue across segment boundaries.
4. Starting and dynamic roads have no intentional pattern discontinuity.
5. Grass remains part of the same collision surface.
6. All automated tests and headless loading pass.
