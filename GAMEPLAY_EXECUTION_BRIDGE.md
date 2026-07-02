# Gameplay Execution Bridge

Phase 20 creates the server-authoritative Gameplay Execution Bridge Foundation for London Engine.

This bridge is the single future gateway between decision-making systems and physical or presentation runtimes. It does not execute gameplay. It validates requests, verifies approvals and dependencies, records queue state, writes an audit trail, and creates dry-run records describing what would execute later.

## Architecture Position

The bridge sits after London Engine decision systems and before any future physical or presentation runtime:

Observation Engine -> Living Cognition Runtime -> Monster Intelligence Foundation -> Narrative Runtime -> Save / Journal / Identity Runtime -> Horror Orchestrator -> Director Coordinator -> Gameplay Execution Bridge -> Future Physical Runtime -> Future Presentation Runtime -> Player.

No future system should mutate world state, presentation state, or gameplay truth directly after a decision has been made. It must submit schema-only evidence to `GameplayExecutionCoordinator`.

## Owns

- execution request intake
- execution request validation
- approval verification
- dependency verification
- bounded queue records
- dry-run scheduling records
- dry-run execution planning
- execution audit history
- diagnostics
- snapshots
- serialization
- deterministic certification self-checks

## Does Not Own

Gameplay Execution Bridge does not own Monster AI, Living Cognition, Narrative, Save, horror pacing, Audio, Lighting, UI, inventory, combat, movement, animation, damage, doors, NPCs, pathfinding, physics, Workspace mutation, Chapter content, story, dialogue, cutscenes, presentation, remotes, or client authority.

## Runtime Entry Point

Use `GameplayExecutionCoordinator.submit(request)` or `GameplayExecutionCoordinator.submitExecutionRequest(request)`.

The request must include:

- `executionId`
- `requester`
- `sourceSystem`
- `executionType`
- `priority`
- `createdAt`
- `expiresAt`
- `dependencies`
- `approvals`
- `metadata`
- `reason`
- `context`

Accepted requests produce `DryRun` records only. Rejected requests produce sanitized diagnostics and audit records.

## Supported Dry-Run Types

- `GameplayStatePlan`
- `PhysicalRuntimePlan`
- `PresentationRuntimePlan`
- `SystemCoordinationPlan`

These are planning schemas. They are not execution commands.

## Validation Boundary

The bridge rejects missing ids, duplicate execution ids, missing approvals, duplicate approval ids, missing dependencies, unverified dependencies, expired requests, unsupported types, unsafe runtime values, cycles, oversized payloads, and forbidden ownership fields.

Forbidden ownership fields include Workspace, UI, remotes, Audio, Lighting, movement, damage, animation, pathfinding, doors, Chapter content, story, dialogue, cutscenes, Monster AI, Save ownership, Narrative ownership, and horror pacing.

## Future Integration

Future physical and presentation runtimes may consume bridge records only after Governance approves their contracts. Those runtimes must remain adapters beneath the bridge; they must not become decision makers, pacing systems, or client-authoritative systems.

The bridge is intentionally strict because it protects the London Engine Constitution from slow architectural drift.
