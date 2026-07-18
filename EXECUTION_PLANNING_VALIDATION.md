# Execution Planning Validation

Phase 148 validation is exact-schema and deterministic.

## Planning Nodes

Planning nodes require:

- `nodeId`
- `nodeKind`
- `authorityOwner`
- `version`
- `orderingKey`
- `planningClassification`
- `metadata`

Unknown fields, missing fields, invalid ids, unsupported enums, unsafe metadata,
and duplicate node ids reject before publication.

## Dependencies

Planning dependencies require:

- `dependencyId`
- `fromNodeId`
- `toNodeId`
- `dependencyKind`
- `requiredVersion`
- `metadata`

Validation rejects missing dependencies, duplicate dependencies, self
dependencies, dependency cycles, illegal required dependencies across different
authority owners, version mismatches, and unknown authority references.

## Constraints

Constraints are validated separately from dependencies. They model planning
conditions such as runtime blocked, authority unavailable, runtime truth
preserved, verification incomplete, planning frozen, and publication locked.

Constraint validation rejects unsupported constraint kinds, duplicate
constraints, unknown node references, unsafe payloads, and over-limit
constraint sets.

## Publication

Publication is allowed only after graph construction, dependency validation,
constraint validation, and eligibility analysis succeed. Failed validation does
not mutate the previously published state.
