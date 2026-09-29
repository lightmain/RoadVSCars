# Tasks: Vehicle Collisions and Fixed Random Targets

## Task 1: Specify Fleet Collision and Random Offsets

**Description:** Add tests defining vehicle collision masks and deterministic,
bounded, distinct target offsets.

**Acceptance criteria:**
- [x] Vehicles collide with road layer 1 and vehicle layer 2.
- [x] Equal nonzero seeds produce equal offsets.
- [x] Lateral and longitudinal offsets remain within configured bounds.

**Verification:**
- [x] Focused fleet tests fail before production changes.

**Dependencies:** None

**Files likely touched:**
- `tests/driving/vehicle_fleet_test.gd`

**Estimated scope:** Small

## Task 2: Specify Target Offset Geometry

**Description:** Add pure geometry tests for offsetting a path target along
the local road-right direction.

**Acceptance criteria:**
- [x] Positive-Z roads offset along positive X.
- [x] Positive-X roads offset along negative Z.
- [x] Degenerate tangents return the original target.

**Verification:**
- [x] Focused control tests fail before production changes.

**Dependencies:** None

**Files likely touched:**
- `tests/driving/vehicle_control_test.gd`

**Estimated scope:** Small

## Task 3: Enable Vehicle-to-Vehicle Collision

**Description:** Include the fleet vehicle layer in each vehicle's collision
mask while preserving road collision.

**Acceptance criteria:**
- [x] Spawned vehicles use layer 2 and mask 3.
- [x] Existing collision shapes and spawn layout are unchanged.

**Verification:**
- [x] Fleet collision tests pass.

**Dependencies:** Task 1

**Files likely touched:**
- `Scenes/Levels/vehicle_fleet.gd`
- `tests/driving/vehicle_fleet_test.gd`

**Estimated scope:** Small

## Task 4: Generate Fixed Bounded Target Offsets

**Description:** Add fleet seed and target-region settings, generate each
variant's offsets once, and clamp lateral range to the road's safe width.

**Acceptance criteria:**
- [x] Runtime seed zero randomizes once; nonzero seed is reproducible.
- [x] Each variant stores lateral and longitudinal offsets.
- [x] Twenty vehicles receive multiple distinct offsets.

**Verification:**
- [x] Seed and bounds tests pass.

**Dependencies:** Task 1

**Files likely touched:**
- `Scenes/Levels/vehicle_fleet.gd`
- `tests/driving/vehicle_fleet_test.gd`

**Estimated scope:** Small

## Task 5: Apply Offsets to AI Targets

**Description:** Configure each AI with its fixed offsets, shift path sampling
longitudinally, and offset the sampled point laterally along road right.

**Acceptance criteria:**
- [x] `BasicAI` receives both offsets from its variant.
- [x] Target geometry follows the path tangent.
- [x] Offset values do not change during control updates.

**Verification:**
- [x] Geometry and instantiated-level tests pass.
- [x] Existing speed and steering tests remain green.

**Dependencies:** Tasks 2 and 4

**Files likely touched:**
- `Scenes/Entities/basic_ai.gd`
- `Scenes/Entities/basic_vehicle.gd`
- `Scripts/Driving/vehicle_control.gd`
- `tests/driving/vehicle_control_test.gd`
- `tests/driving/vehicle_fleet_test.gd`

**Estimated scope:** Medium

## Task 6: Runtime Verification

**Description:** Run the level and inspect physical vehicle interaction and
distributed target behavior.

**Acceptance criteria:**
- [x] Vehicles can physically contact and affect one another.
- [x] Vehicles visibly pursue different positions across the road.
- [x] No parser, scene, or runtime errors occur.

**Verification:**
- [x] Full tests pass.
- [x] Headless import succeeds.
- [x] Runtime scene and logs are inspected.

**Dependencies:** Tasks 3 and 5

**Files likely touched:**
- `docs/vehicle-collisions-random-targets/checklist.md`

**Estimated scope:** Small

## Task 7: Analyze Active Avoidance

**Description:** Compare practical avoidance options for this physics-based
prototype without changing runtime behavior.

**Acceptance criteria:**
- [x] Analysis covers sensing, prediction, decision, and control layers.
- [x] A recommended incremental approach is identified.
- [x] Tradeoffs with collision-heavy gameplay are explicit.

**Verification:**
- [x] Findings are recorded in the final response and checklist.

**Dependencies:** Task 6

**Files likely touched:**
- `docs/vehicle-collisions-random-targets/checklist.md`

**Estimated scope:** Small

## Task 8: Review and Finalize

**Description:** Review the complete change and record verification results.

**Acceptance criteria:**
- [x] No blocking correctness, architecture, security, or performance issues.
- [x] Worktree contains no generated artifacts.
- [x] All success criteria are accounted for.

**Verification:**
- [x] Run `git diff --check`.
- [x] Complete `checklist.md`.

**Dependencies:** Tasks 6 and 7

**Files likely touched:**
- `docs/vehicle-collisions-random-targets/checklist.md`

**Estimated scope:** Small
