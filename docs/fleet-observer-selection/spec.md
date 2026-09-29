# Spec: Fleet Observer Selection

## Assumptions

1. "Left" and "right" mean the keyboard Left and Right arrow keys, not mouse
   buttons and not the existing A/D steering actions.
2. Right selects the next alive vehicle by fleet index; Left selects the
   previous alive vehicle. Selection wraps and skips dead vehicles.
3. Chase and Observer camera modes follow the selected vehicle. Road mode
   remains the road-builder camera.
4. The telemetry HUD follows the selected vehicle.
5. If the selected vehicle dies, another alive vehicle is selected randomly.
6. If no vehicles remain, the road camera becomes current.
7. The selected fleet slot receives a high-contrast outline while retaining
   its alive/dead fill color.

## Objective

Make chase and observer viewing operate across the whole fleet. Start each run
on a random alive vehicle, allow keyboard arrow navigation between surviving
vehicles, show the selected vehicle in the fleet panel, and recover
automatically when that vehicle exits.

## Tech Stack

- Godot 4.7.x
- Typed GDScript signals
- Existing GdUnit4 suite
- Existing per-vehicle chase and observer cameras

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
Scenes/Levels/vehicle_fleet.gd         Owns observed vehicle and input
Scenes/Entities/basic_vehicle.gd       Activates or releases local cameras
Scenes/Temp/ui.gd                      Rebinds telemetry and highlights a slot
tests/driving/vehicle_fleet_test.gd    Selection and camera integration
tests/ui/ui_control_monitor_test.gd    Highlight presentation
```

## Code Style

```gdscript
signal observed_vehicle_changed(index: int, vehicle: BasicVehicle)

func cycle_observed_vehicle(direction: int) -> void:
	var next_index := find_alive_index(
		_vehicle_alive_states,
		_observed_vehicle_index,
		direction
	)
```

- Keep fleet lifecycle and selection state in `VehicleFleet`.
- Communicate selection through typed signals.
- Use physical arrow key events without changing A/D steering.

## Testing Strategy

- Unit-test alive-index traversal, skipping and wrapping.
- Seed observation randomness in integration tests.
- Verify startup selection is alive and owns the active chase camera.
- Verify Left/Right key events move to the expected alive vehicle.
- Verify selected-vehicle deletion chooses another alive vehicle.
- Verify no survivors restore the road camera.
- Verify the fleet panel marks exactly one selected slot.

## Boundaries

- Always: keep one active viewport camera, preserve vehicle AI and physics,
  and ignore key-repeat events.
- Ask first: add mouse selection, clickable fleet slots, or change camera
  transforms.
- Never: poll all nodes every frame, use A/D for observer switching, or alter
  unrelated road generation settings.

## Success Criteria

1. Startup randomly selects exactly one alive vehicle.
2. Right Arrow cycles forward and Left Arrow cycles backward among alive
   vehicles, with wraparound.
3. Dead vehicles are never selected.
4. Selected-vehicle death immediately selects a random survivor.
5. Chase and Observer modes transfer to the new selected vehicle.
6. Telemetry follows the selected vehicle.
7. The corresponding right-panel slot has a visible outline.
8. With no survivors, Road camera is active and no slot is highlighted.
9. Focused tests, the full suite, and headless project loading pass.
