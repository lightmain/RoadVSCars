# Road vs Cars

English | [简体中文](README-CN.md)

Road vs Cars is a Godot 4.7 3D driving prototype built around a road that is
generated while the simulation runs. A controllable road-building camera
defines the route, `DynamicRoad` creates matching mesh and collision segments,
and a fleet of AI vehicles follows the resulting path.

## Features

- Runtime road generation with adaptive segment lengths, collision geometry,
  path sampling, and automatic cleanup.
- A procedural road shader with asphalt, a 9 m / 6 m dashed center line,
  shoulders, and grass.
- A 20-vehicle staggered starting grid with distinct colors, suspension
  profiles, driving parameters, and randomized path targets.
- Pure-pursuit steering, curvature-aware speed planning, PI speed control,
  braking, and heading recovery.
- Vehicle-to-vehicle collisions, off-road detection, and automatic removal of
  vehicles that leave the generated road.
- Road, chase, and observer cameras with live speed, control, and fleet-status
  displays.
- Procedural tire and wheel materials shared by all vehicles.

## Requirements

- [Godot Engine 4.7.x](https://godotengine.org/)
- Forward Plus renderer

GdUnit4 and the Godot AI editor plugin are included in `addons/`; no separate
dependency installation is required for the project itself.

## Run

Open the repository in Godot and run the main scene, or launch it from a
terminal:

```sh
godot --path .
```

On macOS with the standard Godot application:

```sh
'/Applications/Godot.app/Contents/MacOS/Godot' --path .
```

The main scene is `res://Scenes/Levels/level.tscn`. The default viewport is
1600 x 900.

## Controls

| Input | Action |
| --- | --- |
| Mouse position | Steer and pitch the road-building camera |
| `Space` | Temporarily slow the road-building camera |
| `Left` / `Right` | Observe the previous or next surviving vehicle |
| `Road` / `Chase` / `Observer` UI buttons | Select the active camera mode |
| `F` | Toggle fullscreen |
| `Esc` | Toggle mouse capture when capture is enabled |
| `W` / `S` | Manual vehicle throttle and reverse |
| `A` / `D` | Manual vehicle steering |
| `Space` | Manual vehicle brake |

Vehicles use AI control by default. The `W`, `A`, `S`, `D`, and manual brake
controls apply when `BasicVehicle.manual_control` is enabled.

## How It Works

1. `RoadBuilderCamera` moves forward through the world and uses the mouse
   position to define the route direction.
2. `DynamicRoad` samples the camera transform and builds road mesh, collision,
   continuous UVs, and path data.
3. The road shader converts lateral position and cumulative path distance into
   asphalt, shoulders, grass, surface variation, and center-line dashes.
4. `VehicleFleet` creates the vehicle variants and assigns bounded random
   lateral and longitudinal path targets.
5. `BasicAI` projects each vehicle onto the sampled road path and calculates
   steering, throttle, and brake commands.
6. `BasicVehicle` applies those commands through Godot's vehicle physics and
   reports telemetry to the UI.

The road surface is visual only: grass, shoulders, and asphalt share the same
continuous road collision surface.

## Project Structure

```text
Scenes/
  Entities/          Vehicle scene, physics, AI, and wheel material
  Levels/            Main level, road generator, camera, fleet, and road shader
  Temp/              Runtime driving UI
Scripts/Driving/     Road-path and vehicle-control calculations
Graphics/            Source model and texture assets
tests/               GdUnit4 driving and UI tests
docs/                Feature specifications, plans, and checklists
```

The filename `Scenes/Levels/road_meterial.tres` is intentionally preserved
because existing scenes reference that path.

## Tests

Run all GdUnit4 tests:

```sh
./addons/gdUnit4/runtest.sh \
  --godot_binary /path/to/godot \
  --headless --ignoreHeadlessMode \
  --add tests
```

Run a headless project import and script/scene load check:

```sh
godot --headless --path . --editor --quit
```

## Export

The repository contains a Windows Desktop x86_64 export preset:

```sh
godot --headless --path . --export-release RoadVSCars
```

The configured output is `Road vs Cars.exe`.
