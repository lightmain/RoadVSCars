# Implementation Plan: Scene UI and Fleet Status

## Architecture

- `VehicleFleet` owns vehicle identity and lifecycle state.
- `BasicVehicle` emits telemetry without referencing UI nodes.
- `DrivingUI` binds to the fleet, its primary vehicle, and typed signals.
- `Level` owns the single HUD instance and assigns its fleet reference.

## Phase 1: Contracts

- [x] Add failing scene-ownership tests.
- [x] Add failing 20-slot and liveness-update tests.
- [x] Add failing telemetry-binding test.

## Phase 2: Implementation

- [x] Add fleet lifecycle signals and query methods.
- [x] Replace vehicle `$UI` calls with a typed telemetry signal.
- [x] Move the HUD instance from `BasicVehicle.tscn` to `level.tscn`.
- [x] Add and style the right-side fleet panel.
- [x] Bind camera controls and telemetry to the primary vehicle.

## Phase 3: Verification

- [x] Focused tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless import succeeds.
- [x] Runtime desktop and scaled captures have no overlap.
- [x] Code review has no blocking findings.

## Risks

| Risk | Mitigation |
|---|---|
| UI misses fleet spawn signals due to ready order | Query current fleet state when binding |
| Freed vehicles leave stale references | Track bool state and use `tree_exiting` |
| Camera buttons lose their target | Bind once to the fleet's primary vehicle |
| Right panel overlaps speed text | Place it below the speed monitor with fixed anchors |
| Scene serialization becomes noisy | Limit `.tscn` changes to resource and node ownership |
