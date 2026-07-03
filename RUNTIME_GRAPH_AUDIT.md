# Runtime Graph Audit

Phase 37 was implemented as dependency graph schema infrastructure, not startup execution.

Reviewed and enforced:

- nodes are identity records, not live runtime instances
- dependencies are schema relationships, not service resolution
- capabilities are declarations, not execution permissions
- requirements are declarations, not dependency injection
- compatibility records are metadata, not migrations or adapter loading
- ordering records are plan metadata, not lifecycle execution
- startup and shutdown plans are schemas, not commands
- groups are classification records, not execution groups
- graph validation records are summaries, not enforcement
- diagnostics are health-only
- snapshots are schema data

Remaining risk: future systems may try to turn plan schemas into execution commands. Governance and documentation require future orchestration, dependency injection, Framework changes, startup execution, and shutdown execution to be separate governed systems.

## Hardening Findings

- The initial foundation needed additional forbidden markers for Framework mutation, module references, Framework references, runtime objects, execution permissions, migrations, adapter loading, live mutation, execution groups, and enforcement payloads.
- Diagnostics needed explicit compatibility and group integrity posture.
- Self-checks needed per-category unsafe payload proof and per-category runtime limit proof.

## Fixes Made

- Expanded validation and diagnostic sanitization markers.
- Added diagnostics posture for compatibility, groups, Framework mutation, dependency injection, and service resolution.
- Expanded self-checks across category-specific unsafe payloads and every runtime limit.
