# Schema Model

Minimum save schema fields:

- `saveId`
- `schemaVersion`
- `migrationVersion`
- `createdTimestamp`
- `updatedTimestamp`
- `chapterId`
- `objectiveProgress`
- `checkpointProgress`
- `runtimeMetadata`

Persistent objective records contain `objectiveId`, `state`, `completionTimestamp`, and `revision`.

Persistent checkpoint records contain `checkpointId`, `eligible`, `activated`, and `revision`.
