# Tasks: Scene UI and Fleet Status

## Task 1: Define Scene UI Contracts

- [x] Assert vehicles have no UI child and the level has one direct HUD.
- [x] Assert the HUD creates 20 stable status slots.
- [x] Assert vehicle removal changes the corresponding alive state.
- Verify: focused tests fail for missing behavior.

## Task 2: Expose Fleet Lifecycle

- [x] Track 20 vehicle alive states in `VehicleFleet`.
- [x] Expose the primary vehicle.
- [x] Emit typed lifecycle signals when vehicles spawn or leave.
- Verify: fleet lifecycle tests pass.

## Task 3: Decouple Vehicle Telemetry

- [x] Replace `$UI` access with a typed telemetry signal.
- [x] Preserve primary-vehicle-only telemetry and camera behavior.
- Verify: vehicle scene loads without a UI child.

## Task 4: Move and Extend the HUD

- [x] Instantiate the HUD directly under `Level`.
- [x] Bind it to the fleet and primary vehicle.
- [x] Add a compact right-side 4-by-5 fleet status panel.
- Verify: UI and level integration tests pass.

## Task 5: Validate and Review

- [x] Run focused and full tests.
- [x] Run headless import.
- [x] Inspect runtime screenshots at desktop and scaled window sizes.
- [x] Complete five-axis code review and remove generated artifacts.
