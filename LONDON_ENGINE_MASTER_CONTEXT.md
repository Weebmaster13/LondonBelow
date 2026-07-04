# London Engine Master Context

Current certified milestone: completed through Phase 46 - Asset Usage Plan Runtime Foundation.

London Engine is a server-authoritative Roblox horror engine foundation for London Below. The current repository state is still foundation-only: it contains runtime contracts, validators, diagnostics, snapshots, governance records, and documentation, but it does not contain Chapter content, final gameplay content, final UI/art, or live asset execution.

## Certified Through Phase 46

Phase 46 adds the Asset Usage Plan Runtime Foundation under `src/ServerScriptService/AssetUsagePlan/Core`.

The runtime owns metadata schemas for future asset usage planning:

- usage plan definitions
- usage contexts
- usage constraints
- usage dependencies
- usage budgets
- usage accessibility records
- usage audit records
- validation, serialization, diagnostics, snapshots, self-checks, and shutdown cleanup

The runtime is schema-only and metadata-only. It records what future systems intend to use and why, but it never loads, preloads, streams, spawns, plays, displays, applies, or mutates assets.

## Phase 46 Boundary

Asset Usage Plan Runtime does not own:

- asset loading or preloading
- content service execution
- instance creation
- storage mutation
- Workspace mutation
- UI creation
- content streaming
- model spawning
- sound playback
- animation loading
- gameplay execution
- presentation execution
- save execution
- remotes
- client authority
- DataStore, HTTP, messaging, analytics, or telemetry execution
- Chapter content, maps, rooms, story, dialogue, or cutscenes

## Current Development Rule

Future Codex work must treat Phase 46 as a certified boundary, not an execution permission. Any future system that loads assets, applies assets, streams content, spawns models, plays sound, creates UI, mutates instances, or sends asset-related remotes must be implemented as a separate governed runtime with its own contracts, validation, diagnostics, snapshots, self-checks, and production review.
