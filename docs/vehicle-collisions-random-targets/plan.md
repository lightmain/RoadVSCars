# Implementation Plan: Vehicle Collisions and Fixed Random Targets

## Overview

First define deterministic random-offset and collision contracts in tests.
Then add pure target-offset geometry, generate bounded offsets in the fleet,
apply them to each AI, and verify the combined behavior in the running game.
Active avoidance remains a documented follow-up.

## Architecture Decisions

- `VehicleFleet` owns random offset generation and seed configuration.
- `BasicAI` owns target sampling but delegates road-right geometry to
  `VehicleControl`.
- A fixed per-vehicle offset avoids frame-to-frame steering noise.
- Collision filtering changes only at the fleet boundary; vehicle scenes keep
  their existing collision shapes.
- Tests inject a seed so random behavior is reproducible.

## Dependency Graph

```text
Seeded fleet offset generation
    |
    +-- target offset variant fields
    |       |
    |       +-- BasicVehicle.configure_variant
    |               |
    |               +-- BasicAI target sampling
    |                       |
Road-right geometry --------+

Vehicle collision mask ------> VehicleBody3D physical interaction
```

## Task List

### Phase 1: Contracts

- [x] Task 1: Add failing fleet collision and seeded-offset tests.
- [x] Task 2: Add failing road-right target geometry tests.

### Checkpoint: RED

- [x] Focused tests fail for the expected missing behavior.
- [x] Existing production scripts still parse.

### Phase 2: Implementation

- [x] Task 3: Enable vehicle-to-vehicle collision.
- [x] Task 4: Generate bounded, fixed target offsets per vehicle.
- [x] Task 5: Apply offsets to AI path sampling and target geometry.

### Checkpoint: GREEN

- [x] Focused tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless project import succeeds.

### Phase 3: Runtime and Review

- [x] Task 6: Verify collisions and distributed targets in the running game.
- [x] Task 7: Analyze future avoidance strategies without implementing them.
- [x] Task 8: Complete quality review and verification checklist.

### Checkpoint: Complete

- [x] No parser, scene, or node-path errors.
- [x] No generated artifacts remain in the worktree.
- [x] Branch is ready for user review.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Collision pileups destabilize vehicles | Medium | Keep existing spawn spacing and treat pileups as intended behavior |
| Random targets land outside the road | High | Clamp radius using road width and safety margin |
| Per-frame randomness causes steering oscillation | High | Generate once in `VehicleFleet` and store on `BasicAI` |
| Offset direction flips on curved roads | High | Unit-test positive-Z and positive-X tangents |
| All vehicles receive nearly identical targets | Medium | Assert multiple distinct offsets with a deterministic seed |
| Runtime randomness makes tests flaky | High | Inject a nonzero seed in tests |

## Verification Checkpoints

1. RED: new tests fail specifically on old collision mask and missing offsets.
2. GREEN: focused driving tests pass.
3. Regression: all tests and headless import pass.
4. Runtime: collisions occur and vehicles steer toward different target lines.
5. Review: correctness, readability, architecture, security, and performance
   checks have no blocking findings.
