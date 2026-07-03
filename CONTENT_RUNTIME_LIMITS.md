# Content Registry Runtime Limits

Phase 36 keeps registry state bounded.

- Content definitions: bounded by `MaxContentDefinitions`
- Categories: bounded by `MaxCategories`
- References: bounded by `MaxReferences`
- Dependencies: bounded by `MaxDependencies`
- Packages: bounded by `MaxPackages`
- Versions: bounded by `MaxVersions`
- Tags: bounded by `MaxTags`
- Validation failures: bounded by `MaxValidationFailures`
- Snapshot history: bounded by `MaxSnapshotHistory`
- Tags per schema, package members, reference links, dependency links, string length, node count, and payload depth are bounded

Runtime limits prevent early schema infrastructure from becoming unbounded tooling state.
