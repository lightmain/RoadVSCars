# Implementation Plan: F1 Starting Grid

## Architecture

- Keep formation math in `VehicleFleet.build_variants()`.
- Represent the grid with explicit lateral offset, longitudinal spacing, and
  front-slot constants.
- Extend and translate the existing `StartingRoad`; keep its front edge fixed
  at the road-builder camera's initial Z.

## Phases

- [x] Add failing formation and road-coverage tests.
- [x] Replace four-column row math with staggered two-lane offsets.
- [x] Resize and reposition starting mesh and collision together.
- [x] Run focused/full tests and headless loading.
- [x] Inspect runtime grid positions and review the diff.

## Risks

| Risk | Mitigation |
|---|---|
| Rear vehicles spawn off collision | Assert body-clearance bounds in scene |
| Starting and dynamic roads overlap or gap | Keep static front edge at `z=25` |
| Cars collide immediately | Use 6m lateral separation and 9m same-lane gap |
