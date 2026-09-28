# Tasks: Vehicle Control V2

## Task 1: Specify Fixed-Spacing Path Behavior

**Description:** Add GdUnit tests that define resampling, projection,
arc-length lookup, curvature, and pruning behavior before `RoadPath` exists.

**Acceptance criteria:**
- [ ] Tests cover straight and turning paths.
- [ ] Tests cover empty/single-sample input and pruning with global IDs.
- [ ] The new suite fails because production behavior is not implemented.

**Verification:**
- [ ] Run the targeted GdUnit suite and retain the RED result.

**Dependencies:** None

**Files likely touched:**
- `tests/driving/road_path_test.gd`

**Estimated scope:** Small

## Task 2: Implement the Path Model

**Description:** Implement fixed-spacing sample insertion, local projection,
arc-length target lookup, curvature metadata, and safe pruning.

**Acceptance criteria:**
- [ ] Sample spacing and cumulative distance meet test tolerances.
- [ ] Projection returns finite progress and never requires a world-axis check.
- [ ] Pruning preserves monotonic IDs and cumulative distance.

**Verification:**
- [ ] Targeted path tests pass.
- [ ] Headless import succeeds.

**Dependencies:** Task 1

**Files likely touched:**
- `Scripts/Driving/road_path.gd`
- `tests/driving/road_path_test.gd`

**Estimated scope:** Small

## Task 3: Specify and Implement Control Math

**Description:** Add failing tests, then implement Pure Pursuit steering,
curvature speed limits, path-end limits, and throttle/brake splitting.

**Acceptance criteria:**
- [ ] Left/right/straight steering cases have correct sign and bounds.
- [ ] Higher curvature cannot produce a higher curve speed limit.
- [ ] Throttle and brake are finite, clamped, and never active together.

**Verification:**
- [ ] Targeted control tests fail before and pass after implementation.
- [ ] All foundation tests pass together.

**Dependencies:** None

**Files likely touched:**
- `Scripts/Driving/vehicle_control.gd`
- `tests/driving/vehicle_control_test.gd`

**Estimated scope:** Small

## Task 4: Integrate Path Publication

**Description:** Decouple control samples from adaptive road mesh segments and
publish/query the new path through `DynamicRoad`.

**Acceptance criteria:**
- [ ] Camera motion produces fixed-spacing path samples.
- [ ] New samples follow the documented schema.
- [ ] Road cleanup cannot invalidate active progress or access an empty array.

**Verification:**
- [ ] Integration-oriented path tests pass.
- [ ] Headless import succeeds.

**Dependencies:** Task 2

**Files likely touched:**
- `Scenes/Levels/dynamic_road.gd`
- `Scripts/Driving/road_path.gd`
- `tests/driving/road_path_test.gd`

**Estimated scope:** Medium

## Task 5: Integrate AI Commands

**Description:** Replace point popping and PID steering/distance competition
with projection, speed-scaled lookahead, Pure Pursuit, curvature planning, and
bounded PI speed control.

**Acceptance criteria:**
- [ ] AI outputs one dictionary containing throttle, brake, and steering.
- [ ] Cursor progress is monotonic through arbitrary horizontal turns.
- [ ] Missing/short paths return neutral finite commands.

**Verification:**
- [ ] Full GdUnit suite passes.
- [ ] Headless import succeeds.

**Dependencies:** Tasks 2, 3, and 4

**Files likely touched:**
- `Scenes/Entities/basic_ai.gd`
- `Scripts/Driving/vehicle_control.gd`
- `tests/driving/vehicle_control_test.gd`

**Estimated scope:** Medium

## Task 6: Integrate Vehicle Actuation

**Description:** Consume the unified AI command and apply independent positive
engine force, braking, and smoothed steering while retaining manual behavior.

**Acceptance criteria:**
- [ ] AI never requests reverse engine force to slow down.
- [ ] Manual reverse and brake continue to work.
- [ ] Camera switching and speed UI still receive valid values.

**Verification:**
- [ ] Headless import succeeds.
- [ ] Main scene starts without runtime errors.

**Dependencies:** Task 5

**Files likely touched:**
- `Scenes/Entities/basic_vehicle.gd`
- `Scenes/Entities/BasicVehicle.tscn`

**Estimated scope:** Small

## Task 7: Tune Runtime Behavior

**Description:** Tune path spacing, lookahead, lateral acceleration, PI gains,
force, brake, and steering-rate limits from observed gameplay.

**Acceptance criteria:**
- [ ] Car converges to the path without sustained oscillation on straight road.
- [ ] Car slows before sharp turns and accelerates smoothly afterward.
- [ ] No scene-local values refer to removed PID properties.

**Verification:**
- [ ] Run straight, alternating-turn, and sharp-turn scenarios.
- [ ] Capture runtime diagnostics and a gameplay screenshot.

**Dependencies:** Task 6

**Files likely touched:**
- `Scenes/Entities/BasicVehicle.tscn`
- `Scenes/Levels/level.tscn`
- `Scenes/Entities/basic_ai.gd`

**Estimated scope:** Medium

## Task 8: Validate Cleanup and Regressions

**Description:** Run a long enough session to exercise road/path cleanup and
check existing manual, camera, UI, and fullscreen behavior.

**Acceptance criteria:**
- [ ] AI remains on-road for at least 60 seconds with no non-finite commands.
- [ ] Old road and path data are pruned without errors.
- [ ] Existing non-AI controls listed in the spec remain functional.

**Verification:**
- [ ] Complete `checklist.md` with observed results.

**Dependencies:** Task 7

**Files likely touched:**
- `docs/vehicle-control-v2/checklist.md`

**Estimated scope:** Small

## Task 9: Review and Commit

**Description:** Review correctness, robustness, performance, and maintainability,
then commit the implementation on the feature branch.

**Acceptance criteria:**
- [ ] No unresolved high- or medium-severity findings.
- [ ] Full tests and headless import pass after final changes.
- [ ] Worktree contains no generated or out-of-scope files.

**Verification:**
- [ ] Inspect `git diff --check`, final diff, test output, and branch log.

**Dependencies:** Task 8

**Files likely touched:**
- `docs/vehicle-control-v2/checklist.md`

**Estimated scope:** Small
