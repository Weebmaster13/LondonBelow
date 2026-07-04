# London Engine Master Context

Current certified milestone: completed through Phase 49 - Asset Execution Permit Runtime Foundation.

London Engine is a server-authoritative Roblox horror engine foundation for London Below. The current repository state is still foundation-only: it contains runtime contracts, validators, diagnostics, snapshots, governance records, and documentation, but it does not contain Chapter content, final gameplay content, final UI/art, or live asset execution.

## Certified Through Phase 49

Phase 46 added the Asset Usage Plan Runtime Foundation under `src/ServerScriptService/AssetUsagePlan/Core`.

Phase 47 added the Asset Readiness Review Runtime Foundation under `src/ServerScriptService/AssetReadinessReview/Core`.

Phase 48 added the Asset Approval Ledger Runtime Foundation under `src/ServerScriptService/AssetApprovalLedger/Core`.

Phase 49 adds the Asset Execution Permit Runtime Foundation under `src/ServerScriptService/AssetExecutionPermit/Core`.

The Phase 46 runtime owns metadata schemas for future asset usage planning:

- usage plan definitions
- usage contexts
- usage constraints
- usage dependencies
- usage budgets
- usage accessibility records
- usage audit records
- validation, serialization, diagnostics, snapshots, self-checks, and shutdown cleanup

The runtime is schema-only and metadata-only. It records what future systems intend to use and why, but it never loads, preloads, streams, spawns, plays, displays, applies, or mutates assets.

The Phase 47 runtime owns metadata schemas for reviewing whether Asset Manifest and Asset Usage Plan records are ready for future governed execution runtimes:

- readiness checklists
- readiness findings
- readiness gates
- readiness decisions
- readiness audits
- validation, serialization, diagnostics, snapshots, self-checks, and shutdown cleanup

The readiness runtime is also schema-only and metadata-only. It can record readiness concerns, gates, and decisions, but it never loads, preloads, streams, spawns, plays, displays, applies, fixes, or mutates assets.

The Phase 48 runtime owns metadata schemas for formal approval evidence after readiness review:

- approval records
- approval conditions
- approval revocations
- approval audits
- validation, serialization, diagnostics, snapshots, self-checks, and shutdown cleanup

The approval ledger is schema-only and metadata-only. It records approval evidence, conditions, revocations, and audits, but approval records are not execution grants and never load, preload, stream, spawn, apply, display, play, mutate, or execute assets.

The Phase 49 runtime owns metadata schemas for future permit evidence:

- execution permits
- execution permit scopes
- execution permit restrictions
- execution permit audits
- validation, serialization, diagnostics, snapshots, self-checks, and shutdown cleanup

The execution permit runtime is schema-only and metadata-only. It records permit evidence, scopes, restrictions, and audits, but permit records are not operational permission, do not grant client authority, and never load, preload, stream, spawn, apply, display, play, mutate, or execute assets.

## Phase 49 Boundary

Asset Usage Plan Runtime, Asset Readiness Review Runtime, Asset Approval Ledger Runtime, and Asset Execution Permit Runtime do not own:

- actual execution permission
- client authority
- asset loading or preloading
- asset streaming, application, or playback
- content service execution
- instance creation
- storage mutation
- Workspace mutation
- UI creation
- VFX creation
- content streaming
- model spawning
- sound loading or playback
- animation loading
- mesh, texture, material, or decal loading
- gameplay execution
- presentation execution
- save execution
- remotes
- client authority
- DataStore, HTTP, messaging, analytics, or telemetry execution
- Chapter content, maps, rooms, story, dialogue, or cutscenes

## Current Development Rule

Future Codex work must treat Phase 49 as a certified boundary, not an execution permission. Any future system that loads assets, preloads assets, applies assets, streams content, spawns models, plays sound, loads animation, creates UI, creates VFX, mutates instances, grants client authority, or sends asset-related remotes must be implemented as a separate governed runtime with its own contracts, validation, diagnostics, snapshots, self-checks, and production review.
