# Tasks: Fleet Observer Selection

## Task 1: Define Selection Contracts

- [x] Test forward/backward traversal, dead-slot skipping, and wraparound.
- [x] Test deterministic startup selection through a seeded RNG.
- Verify: focused tests fail because selection APIs are absent.

## Task 2: Implement Fleet Selection

- [x] Store indexed vehicle references and the selected vehicle.
- [x] Add random startup and death-fallback selection.
- [x] Add physical Left/Right arrow handling.
- Verify: fleet selection tests pass.

## Task 3: Transfer Cameras and Telemetry

- [x] Release cameras on the previous vehicle.
- [x] Apply the fleet camera mode to the newly selected vehicle.
- [x] Rebind HUD telemetry to selection changes.
- Verify: camera and telemetry integration tests pass.

## Task 4: Highlight Current Vehicle

- [x] Track selected index in `DrivingUI`.
- [x] Add a visible outline to exactly one alive slot.
- [x] Clear highlighting when no vehicles survive.
- Verify: UI style and metadata tests pass.

## Task 5: Validate and Review

- [x] Run focused and full tests.
- [x] Run headless project import.
- [x] Exercise both arrow keys and selected-vehicle deletion behavior.
- [x] Review correctness, architecture, readability, security, and performance.
