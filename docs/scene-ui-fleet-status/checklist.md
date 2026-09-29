# Verification Checklist: Scene UI and Fleet Status

## Ownership

- [x] `BasicVehicle.tscn` has no UI child.
- [x] `Level` owns exactly one direct HUD.
- [x] The HUD survives individual vehicle deletion.

## Binding

- [x] `Vehicle01` drives speed and control telemetry.
- [x] Camera selector controls `Vehicle01`.
- [x] No vehicle script contains a concrete `$UI` path.

## Fleet Panel

- [x] Twenty stable labeled slots are visible.
- [x] Initial count is 20/20.
- [x] Destroyed vehicles become visually inactive.
- [x] Alive count decrements after vehicle removal.
- [x] Panel does not overlap existing HUD elements.

## Verification

- [x] Focused tests pass.
- [x] Full tests pass.
- [x] Headless import succeeds.
- [x] Runtime logs contain no new errors.
- [x] Desktop screenshot reviewed.
- [x] Scaled-window screenshot reviewed.
- [x] `git diff --check` passes.
- [x] Generated artifacts are removed.

## Results

- RED run failed on the missing level HUD and fleet status panel as expected.
- Focused UI and fleet suites passed: 17/17.
- Full GdUnit run passed: 57/57 across 5 suites, with no failures, skipped
  tests, flaky tests, or orphans.
- Headless editor import exited with code 0.
- Runtime inspection confirmed `/Level/UI` is the HUD owner and showed the
  initial `Fleet 20 / 20` state.
- After vehicles exited, their numbered slots changed from green to muted gray,
  the alive count decreased, and the HUD remained visible.
- The 1600-by-900 and 720-pixel scaled captures showed no clipping or overlap.
- Review covered correctness, readability, architecture, security, and
  performance with no blocking findings.
