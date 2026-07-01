# Cognition Validation

Every public Living Cognition API validates before accepting data.

## Validation Rules

- Duplicate cognitive entity IDs reject.
- Missing identifiers reject.
- Invalid IDs reject.
- Invalid confidence rejects.
- Invalid timestamps reject.
- Execution leakage rejects, including nested execution-like fields.
- Workspace references reject.
- Client authority fields reject.
- Movement, pathfinding, navigation, damage, animation, sound, lighting, gameplay, remote, and instance fields reject.
- Invalid thought transitions reject.
- Serialization rejects Roblox Instance references.
- Serialization rejects cyclic table references.
- Serialization rejects functions, threads, userdata, oversized payloads, overly deep payloads, and oversized strings.

## Authority Rule

Living Cognition accepts trusted server observations only. It does not trust clients, does not create remotes, does not mutate the world, and does not execute gameplay.