# Spec: Vehicle Collisions and Fixed Random Targets

## Assumptions

1. Every fleet vehicle should collide with both the road and other vehicles.
2. Each vehicle receives one random target offset when the fleet is created;
   the offset remains fixed for that vehicle until it is destroyed.
3. Each starting column receives lateral targets on the same visual side of
   the road, preventing the columns from crossing immediately after launch.
   For the initial positive-Z road, road-local lateral signs are opposite to
   world-X spawn signs.
4. The default region extends 12 meters laterally and 4 meters longitudinally.
5. Lateral offsets are additionally clamped to the road half-width minus a
   3-meter safety margin.
6. Active collision avoidance is analysis-only in this change. Physical
   collisions and resulting pileups remain valid gameplay.
7. No third-party dependency is required.

## Objective

Make the 20 fleet vehicles physically interact and stop steering every car
toward the road centerline. Each vehicle should pursue a stable, randomly
offset point around its normal path target while keeping that target inside the
road's safe width.

Success means vehicles can bump and block one another, their target points are
spatially distributed, and steering remains stable because target offsets do
not change every frame.

## Tech Stack

- Godot 4.7.x, Forward Plus
- GDScript with static typing where practical
- `VehicleBody3D` collision layers and masks
- GdUnit4 6.2.1

## Commands

```sh
# Run focused driving tests
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode \
  --add tests/driving/vehicle_control_test.gd \
  --add tests/driving/vehicle_fleet_test.gd

# Run all tests
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode --add tests

# Validate scripts and scenes
HOME="$PWD/.tmp-home" \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

## Project Structure

```text
Scenes/Levels/vehicle_fleet.gd       Fleet collision and random offset setup
Scenes/Entities/basic_vehicle.gd     Applies variant values to each BasicAI
Scenes/Entities/basic_ai.gd          Offsets the sampled Pure Pursuit target
Scripts/Driving/vehicle_control.gd   Pure path-target offset calculation
tests/driving/                       Deterministic unit and scene tests
docs/vehicle-collisions-random-targets/  Spec and delivery records
```

## Behavior

### Collision

- Vehicles remain on collision layer 2.
- Their collision mask becomes 3, enabling collisions with road layer 1 and
  vehicle layer 2.
- Existing spawn spacing is retained.

### Fixed Random Target

- `VehicleFleet` owns random generation because it creates vehicle identity
  and per-vehicle variants.
- A local `RandomNumberGenerator` generates lateral and longitudinal offsets.
- Vehicles spawned at negative world X receive positive road-local lateral
  offsets; vehicles spawned at positive world X receive negative offsets.
- A nonzero exported seed produces reproducible layouts; zero randomizes once
  during fleet startup.
- Tests pass an explicit seed and never rely on ambient randomness.
- `BasicAI` samples the path at:

```gdscript
_path_distance + lookahead + target_longitudinal_offset
```

- It then offsets the sampled world position along the road-right vector:

```gdscript
var road_right := Vector3.UP.cross(target["tangent"]).normalized()
var target_position := target["position"] + road_right * target_lateral_offset
```

- Offset values remain unchanged during runtime.
- Speed planning, the 15-meter path-end margin, and the 80 m/s speed ceiling
  remain unchanged.

## Code Style

```gdscript
static func offset_path_target(
	position: Vector3,
	tangent: Vector3,
	lateral_offset: float
) -> Vector3:
	var road_right := Vector3.UP.cross(tangent)
	if road_right.length_squared() <= MIN_DISTANCE:
		return position
	return position + road_right.normalized() * lateral_offset
```

- Tabs for indentation and `snake_case` identifiers.
- Keep random generation out of per-frame AI code.
- Keep geometry calculations in `VehicleControl`.
- Do not hand-edit unrelated scene serialization.

## Testing Strategy

- Begin with failing tests for vehicle collision masks.
- Begin with failing tests proving seeded offsets are stable, bounded, and
  distributed across the fleet.
- Unit-test road-right offset direction for positive-Z and positive-X roads.
- Instantiate the level and verify each `BasicAI` receives its variant offset.
- Run the complete suite and a headless project import.
- Run the game and inspect that vehicles remain active after collisions and
  pursue visibly different lanes.

## Boundaries

- Always: preserve road collision, keep target points inside the configured
  safe road width, use deterministic seeds in tests, retain 15-meter end gap.
- Ask first: add active avoidance, change vehicle count or spawn grid, disable
  collision response, or add dependencies.
- Never: redraw random offsets every frame, write generated `.godot` files, or
  couple target offsets to camera speed.

## Success Criteria

1. Every spawned vehicle has collision layer 2 and collision mask 3.
2. A fixed seed produces the same offsets on repeated calls.
3. Fleet vehicles receive more than one distinct target offset.
4. Every lateral offset stays inside road half-width minus safety margin.
5. Every lateral target stays on the same side as its vehicle's starting slot.
6. Pure Pursuit targets move in the correct road-right direction on turns.
7. Target offsets remain constant over successive physics frames.
8. Existing speed planning, camera controls, off-road cleanup, and UI tests
   continue to pass.
9. The full GdUnit suite and headless import pass.

## Avoidance Follow-up

The implementation intentionally has no active avoidance. A future system can
add local traffic sensing and blend a collision-avoidance offset with the fixed
preferred offset. The post-implementation analysis will compare ray/shape
casts, neighbor prediction, lane selection, and reciprocal velocity methods.

## Open Questions

None blocking.
