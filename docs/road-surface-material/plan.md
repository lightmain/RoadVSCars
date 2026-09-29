# Implementation Plan: Textured Road Surface

## Architecture Decisions

- Use one spatial shader for all surface regions so curved road segments need
  no extra geometry or collision bodies.
- Store longitudinal UV in meters to make line dimensions independent of
  adaptive segment length.
- Keep the existing 40-meter road mesh and collision width unchanged.
- Use world coordinates for the straight starting road and road-distance UV
  for dynamic segments.

## Tasks

1. Add tests for continuous distance UVs and 9/6-meter line constants.
2. Replace per-segment marker coloring with a shared shader material.
3. Assign the shader to the starting road and align its pattern at the join.
4. Run automated and visual verification.
5. Review and commit the feature independently.

## Risks

- BoxMesh UV orientation may differ across faces. The starting road therefore
  uses world X/Z coordinates instead of relying on its UV layout.
- Very sharp dynamic curves can distort texture width locally. The existing
  adaptive segment generation limits this and is unchanged.
- Shader noise must remain subtle enough to keep markings legible.
