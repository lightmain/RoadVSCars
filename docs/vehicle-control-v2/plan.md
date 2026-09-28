# Implementation Plan: Vehicle Control V2

## Overview

Separate geometric path processing from scene and physics code, verify it with
small deterministic tests, then integrate it into road generation and vehicle
control. The dependency order is path model, control math, road publication,
AI integration, vehicle actuation, and runtime tuning.

## Architecture Decisions

- Use cumulative arc length as the common coordinate between road generation
  and vehicle control. This removes dependence on world axes and point density.
- Keep road mesh segments and control-path samples separate. Mesh density can
  adapt for visual/collision quality while path spacing stays deterministic.
- Put stateless controller math in a `RefCounted` utility so tests do not need a
  physics scene.
- Keep controller state in `BasicAI`; keep force, brake, steering smoothing,
  camera, and UI application in `BasicVehicle`.
- Use monotonic sample IDs and cumulative distance so pruning cannot reset
  vehicle progress.

## Dependency Graph

```text
RoadPath fixed-spacing samples
    |
    +-- projection and arc-length sampling
    |       |
    |       +-- DynamicRoad path publication
    |       +-- BasicAI path cursor
    |
    +-- curvature metadata
            |
            +-- speed planner
                    |
Pure Pursuit math --+-- BasicAI command output
                            |
                            +-- BasicVehicle throttle/brake/steering
```

## Task List

### Phase 1: Pure Foundations

- [ ] Task 1: Add failing tests for fixed-spacing path behavior.
- [ ] Task 2: Implement `RoadPath` append, projection, sampling, and pruning.
- [ ] Task 3: Add failing tests and implementation for steering and speed math.

### Checkpoint: Foundations

- [ ] Targeted GdUnit suites pass.
- [ ] Headless Godot import succeeds.
- [ ] No scene files have changed.

### Phase 2: Runtime Integration

- [ ] Task 4: Publish the new path contract from `DynamicRoad`.
- [ ] Task 5: Replace `BasicAI` with path-cursor, Pure Pursuit, and PI control.
- [ ] Task 6: Apply separate throttle and brake commands in `BasicVehicle`.

### Checkpoint: Integration

- [ ] Full GdUnit suite passes.
- [ ] Headless import succeeds.
- [ ] Main scene starts without script or node-path errors.

### Phase 3: Runtime Tuning

- [ ] Task 7: Tune scene-local controller and path values from runtime evidence.
- [ ] Task 8: Exercise winding-road and cleanup scenarios and record results.
- [ ] Task 9: Review the full diff and commit the completed implementation.

### Checkpoint: Complete

- [ ] Every success criterion in `spec.md` is checked.
- [ ] No non-project files were modified.
- [ ] Branch is ready for user review.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Vehicle steering sign differs from geometric convention | High | Unit-test left/right targets, then verify in scene at low speed |
| Generated path gets too short behind cleanup | High | Store global sample IDs/distances and prune only data older than both road and vehicle needs |
| Camera accelerates beyond vehicle capability | High | Cap planned speed and maintain path-end safety margin instead of chasing distance with reverse throttle |
| 3D pitch contaminates horizontal steering curvature | Medium | Use XZ-projected vectors for lateral control and preserve Y only in target position |
| Inspector overrides hide script defaults | Medium | Explicitly update or remove obsolete values in `BasicVehicle.tscn` and validate instantiated properties |
| Physics behavior is difficult to prove headlessly | Medium | Combine pure tests, parser/load checks, runtime logs, screenshots, and a timed manual scenario |

## Verification Checkpoints

1. Foundation: tests prove path and control equations independently.
2. Integration: scripts and scenes load with the new contract.
3. Runtime: controls remain finite and the car stays on winding generated road.
4. Review: inspect diff for contract drift, dead PID code, noisy logs, and
   accidental generated artifacts.
