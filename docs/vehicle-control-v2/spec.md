# Spec: Vehicle Control V2

## Assumptions

1. The road-building camera remains the player's route-authoring input and
   continues moving along local positive Z.
2. One AI-controlled `BasicVehicle` follows the generated road; multi-vehicle
   racing, overtaking, and obstacle avoidance are outside this change.
3. Existing vehicle physics, cameras, manual controls, UI, art, and level
   composition remain usable.
4. The navigation data contract may be replaced because the user explicitly
   allowed changes to road generation, path transfer, and vehicle control.
5. No new third-party dependency is needed. The included GdUnit4 6.2.1
   framework will be used for automated tests.

## Objective

Replace the point-queue and three competing PID controllers with a stable,
frame-rate-independent path-following system. The vehicle must follow roads
that turn in any world direction, anticipate corners, slow with the brake
instead of reverse engine force, and remain stable while old road geometry and
path samples are removed.

The intended player experience is an AI car that follows the continuously
drawn road smoothly, without steering spikes at point boundaries or logic tied
to global Z.

## Tech Stack

- Godot 4.7.x, Forward Plus
- GDScript with static typing where practical
- `VehicleBody3D` and `VehicleWheel3D` for vehicle physics
- GdUnit4 6.2.1 for deterministic unit tests

## Commands

```sh
# Import and validate scripts/scenes
HOME=/tmp/roadvscars-godot-home \
  '/Applications/Godot.app/Contents/MacOS/Godot' \
  --headless --path . --editor --quit

# Run all project tests
HOME=/tmp/roadvscars-godot-home \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary '/Applications/Godot.app/Contents/MacOS/Godot' \
  --headless --add tests

# Run the game for manual verification
'/Applications/Godot.app/Contents/MacOS/Godot' --path .
```

## Project Structure

```text
Scenes/Levels/dynamic_road.gd       Road mesh generation and path publication
Scenes/Entities/basic_vehicle.gd    Physics command application and cameras
Scenes/Entities/basic_ai.gd         Path tracking and speed controller state
Scripts/Driving/road_path.gd        Fixed-spacing path storage and queries
Scripts/Driving/vehicle_control.gd  Pure steering and speed-control math
tests/                              GdUnit suites for driving logic
docs/vehicle-control-v2/            Spec, plan, tasks, and verification record
```

## Path Contract

Each retained path sample is a dictionary with this schema:

```gdscript
{
	"position": Vector3.ZERO,
	"tangent": Vector3.FORWARD,
	"curvature": 0.0,
	"distance": 0.0,
	"index": 0,
}
```

- `distance` is cumulative arc length and never decreases, including after
  old samples are pruned.
- Samples are generated at a fixed world-space interval, independent of frame
  rate and road mesh segmentation.
- `tangent` points along road travel in positive local Z.
- `curvature` is non-negative horizontal heading change per meter.

## Control Model

- Project the vehicle onto nearby path segments using a monotonic hint index.
- Select a target by arc length, not Euclidean distance.
- Scale lookahead from forward speed and clamp it to configured limits.
- Compute steering with Pure Pursuit geometry and apply steering-rate
  smoothing in `BasicVehicle`.
- Plan speed from builder speed, upcoming maximum curvature, lateral
  acceleration limit, and available path length.
- Use a bounded PI controller for positive throttle.
- Use a separate bounded brake command for overspeed; AI throttle never
  becomes reverse engine force.
- Return neutral controls when path data is insufficient or values are not
  finite.

## Code Style

```gdscript
static func curvature_speed_limit(curvature: float, lateral_accel: float) -> float:
	if curvature <= 0.0001:
		return INF
	return sqrt(maxf(lateral_accel, 0.0) / curvature)
```

- Tabs for indentation, `snake_case` members, `PascalCase` classes.
- Export tuning values in coherent Inspector groups.
- Keep pure calculations outside scene nodes where possible.
- Signals are typed and connected directly.
- Comments explain coordinate or controller choices, not syntax.

## Testing Strategy

- Unit test fixed-spacing resampling, projection, arc-length lookup, pruning,
  curvature, Pure Pursuit sign/magnitude, curve speed limits, and mutually
  exclusive throttle/brake outputs.
- Start every behavior change with a failing test, then implement the minimum
  production code needed to pass.
- Run a headless import after each integration checkpoint.
- Run the main scene and inspect runtime errors plus a gameplay screenshot.
- Manually exercise straight roads, alternating turns, sharp turns, road
  cleanup, low-speed startup, and manual controls.

## Boundaries

- Always: preserve positive-Z travel convention, keep commands finite and
  clamped, retain manual control and camera switching, run tests before
  implementation commits.
- Ask first: add external dependencies, replace `VehicleBody3D`, change input
  bindings, or expand scope beyond this project.
- Never: edit `.godot/`, exported builds, temporary/UID files, or embedded
  vehicle mesh data; use reverse engine force as AI braking; infer progress
  from global coordinates.

## Success Criteria

1. All GdUnit tests pass and the project imports headlessly without parser,
   missing-resource, or invalid-node-path errors.
2. Path samples remain approximately fixed-distance apart and cumulative
   distance stays monotonic through turns and pruning.
3. Vehicle progress and lookahead work for roads traveling in any horizontal
   direction, with no global-Z pass check.
4. Steering is finite, clamped, continuous across sample boundaries, and turns
   toward targets on both sides.
5. Tight upcoming curvature lowers target speed; overspeed produces brake with
   zero AI throttle.
6. The vehicle follows a generated winding road for at least 60 seconds while
   old segments are removed, without leaving the road or producing script
   errors.
7. Manual throttle, steering, brake, chase/reverse cameras, speed UI, and
   fullscreen input still work.

## Open Questions

None blocking. Controller constants will be tuned from runtime evidence while
keeping the behavior and boundaries above fixed.
