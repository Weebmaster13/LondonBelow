# Cognition Validation

Every public API validates before accepting data.

## Validation Rules

- Duplicate cognitive entity IDs reject.
- Missing identifiers reject.
- Invalid confidence rejects.
- Invalid timestamps reject.
- Execution leakage rejects.
- Workspace references reject.
- Client authority fields reject.
- Invalid thought transitions reject.
- Serialization rejects Roblox Instance references.
- Serialization rejects cyclic table references.

## Authority Rule

Living Cognition accepts trusted server observations only. It does not trust clients and does not create remotes.
