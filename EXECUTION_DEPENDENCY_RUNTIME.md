# Execution Dependency Runtime

`ExecutionDependencyRuntime` verifies dependency evidence before a dry-run record is created.

## Dependency Examples

- Narrative approved
- Monster Director approved
- Save valid
- Identity valid
- Journal unlocked
- Memory unlocked
- Observation exists

## Rules

- Dependencies are schemas.
- Every dependency needs `dependencyId`, `sourceSystem`, and `status = "Verified"`.
- Missing dependencies reject.
- Unverified dependencies reject.
- Dependency history is bounded.

## Boundary

Dependencies are evidence only. They do not query, mutate, or execute gameplay state.
