# Implementation Plan: Vehicle Heading Recovery

## Overview

Define recovery behavior as pure control math, verify it at threshold and edge
cases, then integrate the result into `BasicAI` without changing normal Pure
Pursuit behavior.

## Architecture Decisions

- `VehicleControl` computes heading error, state transition, and full-lock sign.
- `BasicAI` owns recovery state and exported tuning values.
- Entry and exit thresholds use hysteresis.
- Recovery caps the existing target speed rather than replacing all speed
  planning.

## Task List

### Phase 1: Contract

- [x] Add failing tests for threshold, steering direction, hysteresis, and
  degenerate input.

### Checkpoint: RED

- [x] Focused control tests fail because recovery math is absent.

### Phase 2: Implementation

- [x] Implement pure heading-recovery control.
- [x] Integrate recovery steering and target-speed cap into `BasicAI`.

### Checkpoint: GREEN

- [x] Focused control tests pass.
- [x] Full GdUnit suite passes.
- [x] Headless project load succeeds.

### Phase 3: Review

- [x] Review correctness, maintainability, performance, and test coverage.
- [x] Record feasibility conclusions for the three deferred experiments.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Oscillation around 80 degrees | Medium | Exit at 65 degrees |
| High-speed steering remains limited | High | Apply recovery after normal limiter |
| Vehicle stops and cannot turn | High | Keep an 8 m/s recovery target |
| Rearward target has ambiguous turn side | Low | Use deterministic left lock |
| Speed integral fights recovery | Medium | Reset it when recovery state changes |
