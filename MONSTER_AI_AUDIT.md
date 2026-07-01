# Monster AI Audit

Phase 17 Monster AI Execution Foundation was audited as a server-authoritative dry-run execution substrate. The audit focused on `src/ServerScriptService/AI/MonsterAI/Core` and Phase 17 Monster AI documentation.

## Scope Reviewed

- Approved intent intake and validation.
- Duplicate monster and duplicate intent rejection.
- Unknown monster, expired intent, unsupported intent, and missing approval rejection.
- Unsafe payload, nested execution field, Instance-like field, cyclic payload, unsafe runtime value, and oversized payload rejection.
- Deep-copy boundaries for registry, state, diagnostics, snapshots, and execution records.
- Bounded intent history, execution history, validation failures, snapshot history, and replay-protection intent IDs.
- Dry-run-only enforcement.
- Observation emission safety.
- Shutdown cleanup.
- Governance contract accuracy.

## Hardening Completed

- Added sanitized diagnostics copies for rejected unsafe payloads so functions, threads, userdata, cycles, oversized payloads, and future Roblox Instance values are never stored raw in validation history.
- Bounded the duplicate intent replay cache with `MaxSeenIntentIds`.
- Expanded self-checks to prove malformed definitions, nested unsafe fields, Instance-like fields, cyclic payloads through the service path, unsafe runtime payloads, oversized payloads, diagnostics isolation, snapshot isolation, dry-run record creation, and shutdown cleanup.
- Preserved dry-run-only execution: accepted intents produce audit records only.

## Authority Confirmation

Monster AI Execution Foundation remains server-only. It creates no remotes, accepts no client-owned truth, and performs no Workspace, Lighting, Audio, UI, animation, attack, damage, movement, navigation, pathfinding, model, or NPC execution.

## Remaining Risks

- Real movement and physical adapters are intentionally absent and must be introduced only through a later governed execution phase.
- Observation emission currently uses an existing Monster observation as a generic state signal; future phases should add more precise Observation Registry IDs before real behavior ships.
- Future Monster Director integration must provide approval IDs and must remain the source of approval, not this executor.