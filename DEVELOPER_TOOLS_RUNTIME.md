# Developer Tools Runtime

Phase 30 defines the Developer Tooling Runtime Foundation for London Engine.

This runtime is server-authoritative schema infrastructure for future internal developer tools. It records the shape of tool definitions, inspection requests, debug panels, command schemas, report packages, permission schemas, and audit records.

It does not execute tools.

## Owns

- Tool definition schemas
- Inspection request schemas
- Debug panel schemas
- Command schema records
- Report package schemas
- Permission schemas
- Audit records
- Validation
- Serialization
- Diagnostics
- Snapshots
- Deterministic self-checks
- Shutdown cleanup

## Does Not Own

- Command execution
- Live admin powers
- Remote console
- Player-facing UI
- Studio plugin behavior
- Moderation
- Analytics collection
- Exploit or backdoor tooling
- Workspace mutation
- DataStore reads or writes
- Remotes
- Client authority
- Teleporting
- Gameplay execution
- Save mutation
- Chapter content
- Story, dialogue, or cutscenes

## Runtime Contract

`DeveloperToolsCoordinator` is the public entry point. Future systems may register inert schema records through the coordinator, but they may not use this runtime to execute commands, create remotes, inspect live clients, mutate game state, or grant admin powers.

Any future live developer tooling must be a separate governed runtime with explicit permissions, audit guarantees, and security review.
