# Tasks: Vehicle Heading Recovery

## Task 1: Specify Recovery Control

**Acceptance criteria:**
- [x] Below 80 degrees does not recover; 80 degrees and above does.
- [x] Full-lock steering points toward targets on either side.
- [x] Recovery remains active until the 65-degree exit threshold.
- [x] Degenerate inputs produce finite neutral output.

**Verification:**
- [x] Focused tests fail before implementation and pass afterward.

**Files:** `tests/driving/vehicle_control_test.gd`,
`Scripts/Driving/vehicle_control.gd`

## Task 2: Integrate Recovery Into BasicAI

**Acceptance criteria:**
- [x] Recovery steering bypasses normal speed steering limits.
- [x] Planned target speed is capped at 8 m/s during recovery.
- [x] Speed integral resets on recovery state transitions.
- [x] Existing normal driving path remains unchanged.

**Verification:**
- [x] Full GdUnit suite and headless load pass.

**Files:** `Scenes/Entities/basic_ai.gd`

## Task 3: Review and Document Deferred Experiments

**Acceptance criteria:**
- [x] Review finds no blocking regression.
- [x] Road margins, racing line, and collision avoidance each have a
  feasibility assessment and recommended dependency order.

**Verification:**
- [x] Complete `checklist.md` and run `git diff --check`.

**Files:** `docs/vehicle-heading-recovery/checklist.md`
