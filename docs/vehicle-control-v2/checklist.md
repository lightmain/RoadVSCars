# Verification Checklist: Vehicle Control V2

## Automated

- [x] `road_path_test.gd` passes.
- [x] `vehicle_control_test.gd` passes.
- [x] Full GdUnit suite passes with no skipped tests.
- [x] Headless project import exits successfully.
- [x] `git diff --check` reports no whitespace errors.

## Path

- [x] Samples are fixed-spacing within tolerance.
- [x] Cumulative distance and sample IDs remain monotonic.
- [x] Projection works on straight, left-turning, and right-turning paths.
- [x] Arc-length lookahead does not jump backward.
- [x] Cleanup retains enough path for the active vehicle.

## AI Control

- [x] Commands are finite and clamped at startup.
- [x] Steering turns toward targets on both sides.
- [x] Steering changes smoothly across path sample boundaries.
- [x] Tight curvature reduces target speed before the turn.
- [x] Overspeed uses brake and zero throttle.
- [x] Low-speed acceleration does not divide by zero or spike.

## Runtime

- [x] Main scene starts without parser or resource errors.
- [x] Road mesh and collision remain continuous through turns.
- [x] AI stays on the road for at least 60 seconds.
- [x] Cleanup occurs without breaking path following.
- [x] Chase and reverse cameras switch correctly.
- [x] Speed monitor updates.
- [x] Manual forward, reverse, steering, and brake work.
- [ ] Fullscreen toggle works.
- [x] Gameplay screenshot inspected.

## Review

- [x] Navigation contract is consistent across all consumers.
- [x] Obsolete PID and point-popping code is removed.
- [x] No per-frame debug print remains in changed runtime code.
- [x] No generated artifacts or files outside the repository were modified.
- [x] Final implementation is committed on `feature/vehicle-control-v2`.

## Results

- GdUnit: 17/17 passed, 0 skipped.
- Headless import: exit code 0 with Godot 4.7.2.
- Runtime: 65 seconds through a +56 degree to -56 degree S-turn; vehicle
  remained upright (`up_dot = 0.999998`) at 110.34 km/h.
- Cleanup: forced `max_segments` from 4000 to 120 at runtime; path start
  advanced to 2502 m while vehicle progress remained valid at 2616 m.
- Manual controls produced forward/reverse engine force, steering, and brake;
  chase/reverse camera selection and the speed UI were verified.
- Fullscreen could not be confirmed in the embedded game viewport because the
  host keeps the embedded window in windowed mode.
