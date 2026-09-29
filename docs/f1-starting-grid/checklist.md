# Verification Checklist: F1 Starting Grid

## Formation

- [x] Vehicle 01 is front-most at `z=15`.
- [x] Consecutive vehicles alternate between `x=-3` and `x=3`.
- [x] Consecutive slots are 4.5 meters apart.
- [x] Same-lane vehicles are 9 meters apart.
- [x] All 20 vehicles use unique longitudinal positions.

## Starting Road

- [x] Collision length is 120 meters.
- [x] Visible mesh length is 120 meters.
- [x] Static-road front edge remains at `z=25`.
- [x] Rear-most vehicle body fits within the static road.

## Verification

- [x] Focused fleet tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless import succeeds.
- [x] Runtime position inspection matches the staggered formula.
- [x] `git diff --check` passes.
- [x] Five-axis review has no blocking findings.

## Results

- RED demonstrated the old four-by-five layout.
- Focused fleet suite passed 22/22.
- Full GdUnit suite passed 65/65 including the mesh parity assertion.
- Headless project import exited with code 0.
- Runtime inspection confirmed surviving vehicles at alternating `x=±3` and
  their expected Z positions. Tool latency prevented a reliable frame-zero
  screenshot of all 20 moving vehicles.
