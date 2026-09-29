# Tasks: Textured Road Surface

- [x] Add failing tests for meter-based UVs and dash dimensions.
  - Acceptance: old normalized UV behavior fails the new assertions.
  - Verify: focused dynamic-road test reports RED.

- [x] Implement the shared road shader and continuous dynamic-road UVs.
  - Acceptance: every segment uses cumulative start/end distances.
  - Verify: focused test passes.

- [x] Apply the shader to the starting road without changing collision.
  - Acceptance: starting visual and collision remain 40 meters wide.
  - Verify: scene contract test and headless load pass.

- [x] Validate, review, and commit.
  - Acceptance: full suite passes and gameplay rendering is visually checked.
  - Verify: clean diff check and dedicated git commit.
