# Implementation Plan: Fleet Observer Selection

## Architecture

- `VehicleFleet` owns the selected index, selected vehicle, camera mode, and
  selection RNG.
- `BasicVehicle` exposes camera activation and release without knowing fleet
  policy.
- `DrivingUI` sends camera-mode commands to the fleet and rebinds telemetry
  when selection changes.
- Fleet slot styles combine alive state with a selected outline.

## Phase 1: Contracts

- [x] Add failing pure traversal tests for skip and wrap behavior.
- [x] Add failing integration tests for seeded startup and arrow-key changes.
- [x] Add failing death fallback and UI highlight tests.

## Phase 2: Implementation

- [x] Track indexed vehicle references and selected state in `VehicleFleet`.
- [x] Select a random alive vehicle after spawning.
- [x] Handle non-echo physical Left/Right arrow key presses.
- [x] Transfer the active chase/observer mode between vehicles.
- [x] Rebind telemetry and update fleet-slot highlighting.

## Phase 3: Verification

- [x] Focused tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless import succeeds.
- [x] Runtime selection, deletion fallback, and visual highlight are checked.
- [x] Code review has no blocking findings.

## Risks

| Risk | Mitigation |
|---|---|
| Old vehicle camera steals focus after a switch | Explicitly release its camera mode |
| Spawn order biases random selection | Select only after all vehicles spawn |
| UI misses the initial selection signal | Query current fleet state when binding |
| Focused buttons consume arrow navigation | Handle physical keys at fleet `_input` |
| Deletion leaves stale references | Update alive state before selecting fallback |
