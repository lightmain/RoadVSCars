# Verification Checklist: Fleet Observer Selection

## Selection

- [x] Startup target is random and alive.
- [x] Right Arrow selects the next alive index and wraps.
- [x] Left Arrow selects the previous alive index and wraps.
- [x] Held-key echo events do not switch repeatedly.
- [x] Dead slots are skipped.
- [x] Selected-vehicle death chooses a random survivor.
- [x] No survivors leaves no selected vehicle.

## Camera and Telemetry

- [x] Exactly one viewport camera is current.
- [x] Chase mode follows the selected vehicle.
- [x] Observer mode follows the selected vehicle.
- [x] Road mode remains on the road camera while selection can still change.
- [x] Telemetry comes from the selected vehicle.

## Fleet Panel

- [x] Exactly one selected slot has a visible outline.
- [x] Alive and dead fill colors remain distinct.
- [x] Highlight follows arrow-key selection.
- [x] Highlight clears when no vehicles survive.

## Verification

- [x] Focused tests pass.
- [x] Full test suite passes.
- [x] Headless import succeeds.
- [x] Runtime logs contain no new errors.
- [x] Desktop screenshot shows the selected outline clearly.
- [x] `git diff --check` passes.
- [x] Generated temporary artifacts are removed.

## Results

- RED failed on the missing fleet-selection API as expected.
- Focused fleet tests passed: 21/21.
- Full GdUnit run passed: 64/64 across 5 suites.
- Headless editor import exited with code 0.
- Runtime started on a random alive vehicle with slot 11 outlined.
- Right Arrow moved Chase to the next survivor and Left Arrow moved it back.
- Observer mode retained the selected outline and used its fixed camera offset.
- Selected-death replacement and final-survivor Road fallback passed automated
  integration tests.
- Five-axis review found and corrected one unrelated diagnostics regression;
  no blocking findings remain.
