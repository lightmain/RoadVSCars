# Spec: Vehicle Heading Recovery

## Assumptions

1. "Target direction" is the horizontal direction from the vehicle to its
   current offset Pure Pursuit target.
2. Recovery starts at a configurable 80-degree heading error.
3. Recovery exits below 65 degrees to prevent threshold chatter.
4. Recovery caps target speed at 8 m/s so the vehicle still has enough motion
   for steering to take effect.
5. Recovery steering bypasses the normal high-speed lateral-acceleration limit.
6. Road-edge sensing, racing-line planning, and collision avoidance are
   analysis-only in this change.

## Objective

Detect when an AI vehicle is no longer in a normal cornering attitude, slow it
down, and command full steering toward its current path target until its
heading is corrected.

## Tech Stack

- Godot 4.7.x, Forward Plus
- Typed GDScript
- GdUnit4 6.2.1

## Commands

```sh
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode \
  --add tests/driving/vehicle_control_test.gd

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
Scenes/Entities/basic_ai.gd               Recovery state and controller integration
Scripts/Driving/vehicle_control.gd        Pure heading-recovery calculation
tests/driving/vehicle_control_test.gd      Boundary and finite-value tests
docs/vehicle-heading-recovery/             Specification and verification records
```

## Behavior

- Below 80 degrees, normal Pure Pursuit steering and speed planning apply.
- At or above 80 degrees, steering becomes full lock toward the target.
- While recovering, target speed is the lower of normal planned speed and
  8 m/s.
- Recovery remains active until heading error falls below 65 degrees.
- A directly rearward target uses deterministic left full lock because either
  steering direction is geometrically valid.
- Degenerate or non-finite targets never produce non-finite controls.

## Code Style

```gdscript
var recovery := VehicleControlMath.heading_recovery_control(
	local_target,
	_heading_recovery_active,
	heading_recovery_enter_angle,
	heading_recovery_exit_angle
)
```

- Keep pure geometry in `VehicleControl`.
- Keep state and exported tuning in `BasicAI`.
- Use normalized steering commands in `[-1, 1]`.

## Testing Strategy

- Prove the old behavior lacks recovery using failing pure-unit tests.
- Cover below, exactly at, and above the entry threshold.
- Cover hysteresis, steering sign, rearward ambiguity, and degenerate input.
- Run the full suite and headless scene/script load after integration.

## Boundaries

- Always: preserve normal steering below threshold; clamp commands; reset the
  speed integrator when recovery state changes.
- Ask first: reverse driving, teleport recovery, or changes to vehicle physics.
- Never: add road-edge sensing, racing-line planning, or active avoidance in
  this implementation.

## Success Criteria

1. Heading error below 80 degrees keeps normal control.
2. Heading error at or above 80 degrees enters recovery.
3. Recovery commands full steering with the correct sign.
4. Recovery target speed never exceeds 8 m/s.
5. Recovery exits only after heading error falls below 65 degrees.
6. Outputs remain finite for degenerate targets.
7. Full tests and headless import pass.

## Open Questions

None blocking. Thresholds and speed are exported for runtime tuning.
