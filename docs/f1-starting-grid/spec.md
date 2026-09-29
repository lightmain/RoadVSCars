# Spec: F1 Starting Grid

## Objective

Replace the four-by-five block spawn with an F1-style staggered grid: vehicles
alternate between two lateral lanes and each subsequent vehicle starts farther
back. Extend the static starting road so all 20 vehicles begin on collision.

## Assumptions

1. Vehicle 01 starts at the front-left slot.
2. Consecutive vehicles alternate between `x=-3` and `x=3`.
3. Consecutive slots are separated by 4.5 meters along negative Z.
4. The first slot is at `z=15`; positive Z remains the driving direction.
5. The starting road extends backward while its front edge stays at `z=25`,
   where dynamic road generation begins.

## Tech Stack

- Godot 4.7.x
- GDScript
- Existing GdUnit4 suite

## Commands

```sh
HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode \
  --add tests/driving/vehicle_fleet_test.gd

HOME="$PWD/.tmp-home" \
  ./addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --ignoreHeadlessMode --add tests
```

## Project Structure

```text
Scenes/Levels/vehicle_fleet.gd       Starting-grid offsets
Scenes/Levels/level.tscn             Static starting-road geometry
tests/driving/vehicle_fleet_test.gd  Formation and coverage contracts
```

## Code Style

```gdscript
var lane_offset := -GRID_LATERAL_OFFSET if index % 2 == 0 else GRID_LATERAL_OFFSET
var grid_z := GRID_FRONT_Z - index * GRID_LONGITUDINAL_SPACING
```

## Testing Strategy

- Assert exactly two lateral positions.
- Assert all 20 vehicles have unique descending longitudinal positions.
- Assert adjacent vehicles alternate lanes with fixed longitudinal spacing.
- Assert the starting-road collision covers every vehicle and still meets the
  dynamic-road camera position at its front edge.

## Boundaries

- Always: preserve positive-Z travel, vehicle count, variant tuning, and road
  width.
- Ask first: rotate the grid, change vehicle scale, or add painted grid boxes.
- Never: move the dynamic-road seam or overwrite unrelated scene values.

## Success Criteria

1. Twenty vehicles form two alternating columns with no side-by-side row.
2. Vehicle 01 is the front-most slot.
3. Same-column vehicles have enough longitudinal clearance.
4. All spawn centers and vehicle bodies fit on the static starting road.
5. Static and dynamic road geometry remain contiguous at `z=25`.
6. Tests, headless loading, and runtime visual inspection pass.
