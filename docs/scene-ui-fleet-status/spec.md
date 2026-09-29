# Spec: Scene UI and Fleet Status

## Assumptions

1. The existing HUD becomes a direct child of `Level`, not any vehicle.
2. `Vehicle01` remains the primary vehicle for telemetry and camera controls.
3. Destroying the primary vehicle does not promote another vehicle in this
   change; the existing road-camera fallback remains.
4. The fleet panel always shows 20 stable slots in a compact 4-by-5 grid.
5. Alive slots are green and dead or unspawned slots are muted gray.
6. The user's `dynamic_road.gd` road-width change is preserved untouched.

## Objective

Move the driving HUD out of `BasicVehicle.tscn` and into the level scene so it
survives vehicle deletion and has scene-wide ownership. Add a right-side fleet
panel that reports which of the 20 vehicles are still alive and shows the
current alive count.

## Tech Stack

- Godot 4.7.x
- GDScript typed signals
- Existing GdUnit4 test suite
- Existing `Scenes/Temp/ui.tscn` HUD resource

## Commands

```sh
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode \
  --add tests/ui/ui_control_monitor_test.gd \
  --add tests/driving/vehicle_fleet_test.gd

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
Scenes/Levels/level.tscn               Owns the HUD instance
Scenes/Levels/vehicle_fleet.gd         Exposes primary vehicle and alive state
Scenes/Entities/BasicVehicle.tscn      No HUD child
Scenes/Entities/basic_vehicle.gd       Emits primary-vehicle telemetry
Scenes/Temp/ui.tscn                    Adds the fleet status panel
Scenes/Temp/ui.gd                      Binds fleet, telemetry, and camera UI
tests/ui/                              HUD behavior tests
tests/driving/                         Level and fleet lifecycle tests
```

## Code Style

```gdscript
signal vehicle_liveness_changed(index: int, alive: bool)

func get_vehicle_alive_states() -> Array[bool]:
	return _vehicle_alive_states.duplicate()
```

- Use typed signals and direct references.
- Keep vehicle physics independent of concrete UI node paths.
- Use stable panel dimensions and fixed status slots.

## Testing Strategy

- RED: assert `BasicVehicle` has no `UI` child and `Level` owns one HUD.
- RED: assert the HUD builds 20 status slots and updates a slot after a vehicle
  exits the tree.
- RED: assert the scene HUD remains after a vehicle is deleted.
- Preserve existing monitor and camera-selector tests.
- Run focused tests, the full suite, headless import, and runtime screenshots.

## Boundaries

- Always: preserve camera behavior, telemetry values, off-road cleanup, and
  the 20-vehicle default.
- Ask first: promote a new primary vehicle, change vehicle count, or redesign
  the complete HUD.
- Never: poll the scene tree every frame, keep `$UI` paths in vehicle code, or
  alter the user's unrelated road-width edit.

## Success Criteria

1. `BasicVehicle.tscn` contains no UI instance.
2. `level.tscn` contains one direct scene-level HUD.
3. Existing speed, control, and camera controls operate on `Vehicle01`.
4. The right panel contains 20 labeled status slots and an alive-count label.
5. Removing any vehicle marks its slot dead and decrements the count.
6. Removing a vehicle does not remove the HUD.
7. All tests and headless project loading pass.
8. Desktop and scaled runtime captures show no overlap.

## Open Questions

None blocking.
