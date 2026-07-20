# Objective Registry

The registry owns immutable objective definitions after validation. It rejects duplicate objective IDs, malformed fields, invalid prerequisite modes, unsupported condition kinds, missing graph references, oversized arrays, unsafe payloads, and cycles before state mutation.

Objective fields:

- `objectiveId`
- `titleKey`
- `descriptionKey`
- `chapterId`
- `priority`
- `prerequisites`
- `completionConditions`
- `failureConditions`
- `nextObjectives`
- `optionalObjectives`
- `checkpointEligible`
- `tags`
- `metadata`
