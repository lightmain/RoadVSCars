# Verification Checklist: Vehicle Control V2

## Automated

- [ ] `road_path_test.gd` passes.
- [ ] `vehicle_control_test.gd` passes.
- [ ] Full GdUnit suite passes with no skipped tests.
- [ ] Headless project import exits successfully.
- [ ] `git diff --check` reports no whitespace errors.

## Path

- [ ] Samples are fixed-spacing within tolerance.
- [ ] Cumulative distance and sample IDs remain monotonic.
- [ ] Projection works on straight, left-turning, and right-turning paths.
- [ ] Arc-length lookahead does not jump backward.
- [ ] Cleanup retains enough path for the active vehicle.

## AI Control

- [ ] Commands are finite and clamped at startup.
- [ ] Steering turns toward targets on both sides.
- [ ] Steering changes smoothly across path sample boundaries.
- [ ] Tight curvature reduces target speed before the turn.
- [ ] Overspeed uses brake and zero throttle.
- [ ] Low-speed acceleration does not divide by zero or spike.

## Runtime

- [ ] Main scene starts without parser or resource errors.
- [ ] Road mesh and collision remain continuous through turns.
- [ ] AI stays on the road for at least 60 seconds.
- [ ] Cleanup occurs without breaking path following.
- [ ] Chase and reverse cameras switch correctly.
- [ ] Speed monitor updates.
- [ ] Manual forward, reverse, steering, and brake work.
- [ ] Fullscreen toggle works.
- [ ] Gameplay screenshot inspected.

## Review

- [ ] Navigation contract is consistent across all consumers.
- [ ] Obsolete PID and point-popping code is removed.
- [ ] No per-frame debug print remains in changed runtime code.
- [ ] No generated artifacts or files outside the repository were modified.
- [ ] Final implementation is committed on `feature/vehicle-control-v2`.

## Results

Pending implementation.
