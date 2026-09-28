# AGENTS.md

## Project Overview

Road vs Cars is a small Godot 4.7 3D driving prototype. A scripted camera
continuously moves through the world, `DynamicRoad` builds road mesh and
collision segments behind it, and a `BasicVehicle` follows the emitted
navigation points with PID-based AI control.

- Engine: Godot 4.7.x, Forward Plus renderer
- Language: GDScript
- Main scene: `res://Scenes/Levels/level.tscn`
- Target viewport: 1600 x 900
- Export preset: Windows Desktop, x86_64
- Automated tests: none

## Repository Layout

- `project.godot`: project settings, input actions, and main scene.
- `export_presets.cfg`: Windows export configuration.
- `Scenes/Levels/level.tscn`: composition root for environment, road builder,
  vehicle, and road-building camera.
- `Scenes/Levels/camera_3d.gd`: `RoadBuilderCamera`; handles mouse steering,
  acceleration, camera movement, fullscreen, and mouse capture.
- `Scenes/Levels/dynamic_road.gd`: `DynamicRoad`; creates road meshes,
  collision bodies, and navigation points at runtime.
- `Scenes/Levels/road_meterial.tres`: base road material. Keep the existing
  misspelled filename because scenes reference it by path.
- `Scenes/Entities/BasicVehicle.tscn`: active vehicle scene, including wheels,
  AI, chase/reverse cameras, and UI.
- `Scenes/Entities/basic_vehicle.gd`: vehicle physics, camera switching,
  manual/AI control selection, and navigation point consumption.
- `Scenes/Entities/basic_ai.gd`: steering, speed, and distance PID controllers.
- `Scenes/Entities/car_skins.tscn`: large imported vehicle mesh resource.
- `Scenes/Temp/ui.tscn` and `ui.gd`: runtime speed display.
- `Graphics/`: source Blender model and texture assets.

Do not edit `.godot/`, exported `.exe`/`.pck` files, `*.tmp`, or `*.uid`
files as source. They are generated artifacts or editor recovery data. Avoid
hand-editing the large embedded mesh data in `car_skins.tscn`; change the
source asset and reimport it through Godot instead.

## Runtime Architecture

The main data flow is:

1. `RoadBuilderCamera._process()` increases `backward_speed`, applies smoothed
   mouse-controlled rotation, and moves along its local positive Z axis.
2. `DynamicRoad._process()` samples that camera transform and creates adaptive
   road segments with mesh and convex collision geometry.
3. Every `navigation_point_interval` segments, `DynamicRoad` stores and emits
   `new_navigation_point`.
4. `BasicVehicle` copies the existing points on startup, subscribes to new
   points, and removes points after passing them.
5. `BasicAI` reads the vehicle's point queue and target camera speed to produce
   throttle and steering commands.

The navigation point dictionary is a shared contract with these keys:

```gdscript
{
	"position": Vector3,
	"basis": Basis,
	"pitch": float,
	"index": int,
}
```

Keep this schema synchronized across `dynamic_road.gd`, `basic_vehicle.gd`,
and `basic_ai.gd`. The current movement logic treats local/global positive Z
as the forward road direction.

## Scene Contracts

Scripts rely on exact child paths and exported references:

- `BasicVehicle` requires `CameraPivot/Camera3D`,
  `CameraPivot/ReverseCamera`, `BasicAI`, and `UI`.
- `UI` requires `SpeedMonitor/MarginContainer/Label`.
- `BasicAI` must remain a direct child of `BasicVehicle`.
- `BasicVehicle.dynamic_road` must point to the level's `DynamicRoad`.
- `DynamicRoad.camera` must point to the level's road-building `Camera3D`.
- `RoadBuilderCamera.dynamic_road` must point back to `DynamicRoad`.

When renaming or moving nodes, update every `$NodePath`, `@onready` reference,
and exported `NodePath` in the owning `.tscn` file. Prefer assigning exported
references in the Godot Inspector.

`RoadBuilderCamera.enabled` is a custom script property. Setting it to `false`
only makes the camera non-current; it does not stop `_process()`. In the
current level this camera remains the road generator while the vehicle chase
camera renders the view.

Scene-local Inspector values override script defaults. Check the instantiated
values in `level.tscn` and `BasicVehicle.tscn` before tuning constants.

## Coding Conventions

- Follow the existing Godot 4 GDScript style: tabs for indentation,
  `snake_case` for variables/functions/signals, and `PascalCase` for
  `class_name`.
- Add static types to exported values, state, parameters, and return values
  when practical.
- Use `@export_group`, `@export`, and `@onready` for editor-facing settings and
  scene references.
- Put frame-rate-independent movement in `_process(delta)` and vehicle physics
  in `_physics_process(delta)`.
- Clamp PID integrals and command outputs. Guard divisions by `delta`,
  distance, or speed against zero.
- Use typed signals and direct signal connections for communication between
  scene owners. Avoid adding global singletons for local relationships.
- Preserve the separation of responsibilities: camera defines the route,
  road builds geometry/navigation data, AI computes commands, and vehicle
  applies physics.
- Keep comments focused on non-obvious coordinate, physics, or control logic.
  Existing comments are mostly Chinese; either Chinese or concise English is
  acceptable, but stay consistent within a changed block.
- Do not perform unrelated formatting changes in `.tscn` files. Prefer editor
  changes for scene resources to avoid noisy serialized diffs.

## Input and Behavior

Input actions from `project.godot`:

- `W` / `S`: forward and backward throttle in manual mode.
- `A` / `D`: left and right steering in manual mode.
- `Space`: brake.
- Mouse position: controls the road-building camera when
  `mouse_input_enabled` is true.
- `F`: toggles fullscreen.
- `Esc`: toggles mouse capture only when `mouse_capture` is enabled.

The active `BasicVehicle.tscn` defaults to AI control
(`manual_control = false`) and enables its chase/reverse cameras.

## Run and Validate

On macOS with the standard Godot application:

```sh
'/Applications/Godot.app/Contents/MacOS/Godot' --path .
```

If `godot` is on `PATH`:

```sh
godot --path .
```

Perform a headless project import and script/scene load check with:

```sh
godot --headless --path . --editor --quit
```

Export the configured Windows build with:

```sh
godot --headless --path . --export-release RoadVSCars
```

After gameplay-related changes, manually verify:

1. The project opens without parser, missing-resource, or invalid-node-path
   errors.
2. The road extends continuously and both mesh and collision follow turns.
3. Old segments are removed after `max_segments` without breaking the
   navigation queue.
4. AI throttle and steering remain finite at startup and through sharp turns.
5. The vehicle switches between chase and reverse cameras correctly.
6. Manual controls work when `manual_control` is enabled.
7. The speed monitor updates and `F` toggles fullscreen.

There is currently no unit-test framework. For behavior changes, report the
headless load result and the manual scenarios exercised. Runtime logging can
be noisy because `basic_vehicle.gd` currently prints reverse-camera state
every physics frame; do not rely on a quiet console as a success criterion.
