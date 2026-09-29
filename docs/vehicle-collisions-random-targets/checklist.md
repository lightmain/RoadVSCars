# Verification Checklist: Vehicle Collisions and Fixed Random Targets

## Automated

- [x] New tests demonstrated RED before implementation.
- [x] Focused fleet and control tests pass.
- [x] Full GdUnit suite passes with no skipped tests.
- [x] Headless project import exits successfully.
- [x] `git diff --check` reports no whitespace errors.

## Collision

- [x] Fleet vehicles remain on collision layer 2.
- [x] Fleet vehicle masks include road layer 1.
- [x] Fleet vehicle masks include vehicle layer 2.
- [x] Existing spawn spacing prevents initial body overlap.

## Target Distribution

- [x] Fixed seeds reproduce the same offsets.
- [x] Runtime seed zero randomizes only during fleet initialization.
- [x] Lateral offsets stay inside the safe road width.
- [x] Lateral targets stay on the same visual side as their starting column,
  accounting for opposite world-X and road-local signs.
- [x] Longitudinal offsets stay inside the configured radius.
- [x] Multiple vehicles receive distinct offsets.
- [x] AI offsets remain constant during runtime.

## Runtime

- [x] Main scene starts without parser or resource errors.
- [x] Vehicles can collide with and push one another.
- [x] Vehicles pursue visibly different road positions.
- [x] Road collision and off-road cleanup still function.
- [x] Camera controls and UI still function.
- [x] Runtime logs contain no new errors.

## Avoidance Analysis

- [x] Candidate sensing methods are compared.
- [x] Collision prediction and priority rules are described.
- [x] A recommended incremental implementation is recorded.
- [x] A no-avoidance gameplay mode remains possible.

## Review

- [x] Correctness reviewed.
- [x] Readability and simplicity reviewed.
- [x] Architecture reviewed.
- [x] Security reviewed.
- [x] Performance reviewed.
- [x] No generated files are included.

## Results

- Focused driving tests passed: 40/40.
- Full GdUnit run passed: 73/73 across 5 suites, with no failures, skipped
  tests, flaky tests, or orphans.
- Headless editor import exited with code 0.
- Runtime inspection found 20 distinct AI offset pairs. Lateral values stayed
  within `[-12, 12]`, longitudinal values stayed within `[-4, 4]`, and every
  inspected AI retained `path_end_margin = 15`.
- Runtime vehicle inspection confirmed collision layer 2 and mask 3.
- In a controlled lateral head-on test, two vehicles started at `12 m/s` and
  `-12 m/s`. After contact their lateral speeds were approximately `0.14 m/s`
  and `-0.20 m/s`, with their centers separated by about `3.42 m`; the
  collision telemetry path also recorded the impact.
- The normal fleet run rendered vehicles pursuing visibly different road
  positions. Game logs contained telemetry only and no new errors.

## Avoidance Design

### Sensing

- A forward `Area3D` per vehicle is the best first broad phase. It can monitor
  vehicle layer 2 without changing physical collision response and yields a
  small neighbor set for 20 vehicles.
- One or two forward `ShapeCast3D` nodes are useful for emergency braking and
  validate the actual swept vehicle width. Ray casts alone are too narrow for
  side contacts and merging traffic.
- Full-space physics queries or a fleet-wide spatial index are unnecessary at
  the current scale. They become useful only if the fleet grows substantially.

### Prediction

Project each neighbor's relative position and velocity into the current road
frame. Compute closest-approach time and distance over a short horizon:

```text
t_closest = clamp(-dot(relative_position, relative_velocity)
                  / max(length_squared(relative_velocity), epsilon),
                  0, prediction_horizon)
```

A conflict exists when closest distance is below combined vehicle clearance.
Rear-end conflicts should also use road-path progress and closing speed because
that remains stable on curved roads.

### Decision

- Keep the fixed random offset as each vehicle's preferred lane position.
- Evaluate a small set of candidate lateral offsets around that preference.
  Score edge clearance, predicted collision risk, deviation from preference,
  and offset switching.
- Use path progress as the primary right-of-way rule: a trailing vehicle yields
  to a leading vehicle. Break equal-priority ties with stable fleet index so
  two vehicles do not make mirrored decisions forever.
- Add hysteresis and a minimum hold time before changing the selected offset.

### Control

- Longitudinal response comes first: reduce target speed from closing distance
  and time-to-collision, with an emergency-brake threshold from `ShapeCast3D`.
- Blend the selected avoidance offset toward `BasicAI.target_lateral_offset`
  with a bounded rate. Do not teleport vehicles or redraw random targets.
- Feed the blended target through the existing Pure Pursuit controller so
  steering and lateral-acceleration limits remain authoritative.

### Recommended Increment

1. Add an `avoidance_enabled` fleet/vehicle toggle, defaulting to off until
   tuned; off is the current collision-heavy mode.
2. Add `Area3D` neighbor sensing and pure TTC/closest-distance helpers with
   deterministic tests.
3. Add following-distance speed reduction and emergency braking.
4. Add candidate lateral-offset selection, rate limiting, and hysteresis.
5. Consider reciprocal velocity methods only later. ORCA-style velocity
   selection does not directly model nonholonomic steering or `VehicleBody3D`
   tire dynamics and is excessive for the current prototype.
