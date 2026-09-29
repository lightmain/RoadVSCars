# Tasks: F1 Starting Grid

- [x] Test two-lane alternation, ordering, and spacing.
  - Verify: focused fleet tests fail on the old four-by-five layout.
  - Files: `tests/driving/vehicle_fleet_test.gd`

- [x] Implement staggered grid offsets.
  - Acceptance: 20 unique Z slots alternate between two X positions.
  - Verify: formation tests pass.
  - Files: `Scenes/Levels/vehicle_fleet.gd`

- [x] Extend the static starting road backward.
  - Acceptance: every vehicle body fits and the front edge remains at `z=25`.
  - Verify: scene integration test and headless load pass.
  - Files: `Scenes/Levels/level.tscn`

- [x] Validate and review.
  - Acceptance: full tests pass and runtime view shows an F1-style grid.
  - Verify: screenshot, logs, and five-axis review.
