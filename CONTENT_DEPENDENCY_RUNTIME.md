# Content Dependency Runtime

Dependencies describe required relationships between registered content definitions.

A dependency requires:

- `dependencyId`
- `ownerSystem`
- `sourceContentId`
- `requiredContentId`

Both endpoints must exist. Direct self-dependencies reject. Future dependency graph analyzers can build on this foundation, but Phase 36 does not execute dependency loading or resolve runtime assets.

Dependencies are policy data, not loader commands.

## Hardening Notes

Dependencies require existing source and required content definitions. Direct self-dependencies reject. Dependency records do not execute load order, trigger asset loading, mutate runtime state outside the registry, run migrations, patch content, or affect save data.
