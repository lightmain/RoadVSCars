# Verification Checklist: Vehicle Heading Recovery

## Automated

- [x] New recovery tests demonstrated RED.
- [x] Focused vehicle-control tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless project load succeeds.
- [x] `git diff --check` succeeds.

## Behavior

- [x] Normal steering remains active below the entry threshold.
- [x] Recovery starts at 80 degrees.
- [x] Recovery uses full steering toward the target.
- [x] Recovery target speed is capped at 8 m/s.
- [x] Recovery exits below 65 degrees.
- [x] Degenerate inputs remain finite.

## Review

- [x] Correctness and edge cases reviewed.
- [x] Existing user changes preserved.
- [x] No deferred experimental feature was implemented.

## Results

- Recovery unit tests demonstrated RED before implementation.
- Focused control tests passed: 34/34.
- Fleet integration tests passed: 23/23.
- Full GdUnit suite passed: 72/72 across 5 suites, with no failures,
  errors, skipped tests, flaky tests, or orphans.
- Headless editor import and a 300-frame headless game run exited successfully.
- A scene-level test rotated a configured vehicle by 100 degrees and confirmed
  full steering plus an 8 m/s target-speed ceiling.

## Deferred Experiment Analysis

### Road-Edge Distance

High feasibility and low cost. Project the vehicle onto `RoadPath`, construct
the road-right axis from the local tangent, and use the signed lateral offset
as road coordinate `d`. With half-width `w`, vehicle half-width `h`, and
positive `d` toward road right:

```text
left_clearance  = w + d - h
right_clearance = w - d - h
```

This geometric result is preferable to ray casts for planning because it is
stable on curves and already uses the generated road's source of truth.
Shape casts can later validate physical edges if barriers or variable-width
geometry are added.

### Outside-Inside-Outside Racing Line

Feasible with medium complexity. Use the existing future curvature profile to
group same-direction curvature into corners, locate an apex near peak
curvature, and generate a smooth lateral-offset profile: outside before
turn-in, inside at the apex, outside on exit. Clamp every offset by the edge
clearances above and limit lateral offset rate so Pure Pursuit receives a
continuous target.

The dynamic road limits planning to the generated horizon, so the planner
should degrade to centerline driving when a complete corner is not yet
visible. This feature should replace the current fixed random offset as the
base line rather than adding both offsets.

### Vehicle Collision Avoidance

Feasible, but highest complexity. Use an `Area3D` as a cheap neighbor broad
phase and a forward `ShapeCast3D` for emergency braking. Convert neighbors to
road coordinates `(s, d)`, predict time and distance at closest approach, and
first add longitudinal following/braking. Lateral avoidance can then score a
small set of candidate offsets using collision risk, edge clearance, racing
line deviation, and switching cost.

Stable right-of-way rules, hysteresis, and minimum maneuver hold time are
required to prevent two vehicles from repeatedly choosing mirrored actions.
Avoidance should temporarily override the racing line, then blend back to it.
NavigationAgent/ORCA is not the first choice because its holonomic velocity
output does not directly respect `VehicleBody3D` steering dynamics.

### Recommended Order

1. Establish shared `(s, d)` road-coordinate and edge-clearance helpers.
2. Add outside-inside-outside planning with bounded, smoothed offsets.
3. Add longitudinal following and emergency braking.
4. Add lateral collision avoidance and deterministic right-of-way.
