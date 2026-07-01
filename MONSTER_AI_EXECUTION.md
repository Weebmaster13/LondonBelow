# Monster AI Execution Foundation

Phase 17 creates the server-authoritative Monster AI execution foundation for London Engine.

This is not Monster AI behavior yet. It is the reusable dry-run execution substrate that future physical monster systems will use after Directors, Horror Orchestration, Monster Intelligence, Living Cognition, Observation Engine, Gameplay Execution Bridge, and Governance approve intent.

## Purpose

Monster AI execution receives approved monster intent/context and records what future physical behavior would do. It does not decide what the monster wants, when horror should escalate, when story reveals happen, or whether a scare is earned.

## Runtime Modules

- `MonsterAIService`: lifecycle, registration, approved-intent intake, diagnostics, snapshots, and observation hooks.
- `MonsterAIRegistry`: server-owned monster execution definitions, with no Roblox Instances.
- `MonsterAIState`: bounded intent, execution, validation, snapshot, and replay-protection history.
- `MonsterAIValidator`: approval, intent, metadata, unsafe field, expiration, and dry-run validation.
- `MonsterAIDiagnostics`: read-only health and runtime inspection.
- `MonsterAISnapshots`: isolated snapshot export.
- `MonsterAISerialization`: deep-copy, diagnostics sanitization, and safe serialization boundary.
- `MonsterAISelfChecks`: deterministic certification scenarios.
- `IntentConsumer`: normalizes approved intent/context.
- `BehaviorExecutorFoundation`: routes validated intents to inert dry-run planners.
- `PerceptionBridge`: future perception execution record only.
- `NavigationIntentBridge`: future navigation need record only; no pathfinding.
- `ChaseIntentFoundation`: future chase preparation record only.
- `StalkIntentFoundation`: future stalk preparation record only.
- `WatchIntentFoundation`: future watch preparation record only.
- `RetreatIntentFoundation`: future retreat preparation record only.

## Accepted Intent Flow

1. A future Director-approved system submits intent to `MonsterAIService.consumeApprovedIntent`.
2. `IntentConsumer` normalizes the payload.
3. `MonsterAIValidator` rejects missing approvals, unknown intent kinds, expired requests, malformed values, unsafe metadata, Roblox Instances, cycles, oversized payloads, and execution-like fields.
4. `MonsterAIRegistry` proves the monster is known.
5. `BehaviorExecutorFoundation` routes to the correct dry-run foundation.
6. `MonsterAIState` records accepted intent, planned execution, and dry-run application.
7. `MonsterAIService` emits a server observation for future monitoring outside self-check mode.

## Dry-Run Only

Every accepted intent becomes an audit record. No path is calculated, no monster moves, no Humanoid is touched, no model is spawned, no sound plays, no Lighting changes, no Workspace part changes, no UI appears, and no client remote is created.

## Future Expansion

Future physical adapters may consume these records only after a later phase explicitly enables real execution through Governance and the proper execution bridge. Those adapters must still require Director approval and must continue emitting observations.