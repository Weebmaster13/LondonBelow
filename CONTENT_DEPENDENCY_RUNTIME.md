# Content Dependency Runtime

Dependencies describe required relationships between registered content definitions.

A dependency requires:

- `dependencyId`
- `ownerSystem`
- `sourceContentId`
- `requiredContentId`

Both endpoints must exist. Direct self-dependencies reject. Future dependency graph analyzers can build on this foundation, but Phase 36 does not execute dependency loading or resolve runtime assets.

Dependencies are policy data, not loader commands.
