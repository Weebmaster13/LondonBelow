# Director Ecosystem

Phase 7 establishes the London Engine Director Ecosystem under `ServerScriptService/Core/Directors`.

This is architecture only. It does not add Chapter 1, Monster AI, final UI, final art, actual scares, real lighting behavior, real audio behavior, real music behavior, or gameplay logic.

## Golden Flow

```text
Observation Engine
-> DirectorCoordinator
-> foundation Directors
-> request routing
-> conflict resolution
-> approval response
-> future execution systems
-> client presentation
```

The Observation Engine records trusted server facts. Directors interpret those facts. The Coordinator routes Director requests and records decision traces. Future execution systems may only act on approved decisions, and client systems remain presentation-only.

## Canonical Modules

`src/ServerScriptService/Core/Directors` contains:

- `DirectorCoordinator.lua`: lifecycle, registration, observation routing, pending request ownership, diagnostics, snapshots, and self-checks.
- `DirectorRegistry.lua`: foundation Director descriptions for Psychological Horror, Narrative, Story, Environment, Lighting, Audio, Music, Monster, Puzzle, Save, Difficulty, and Performance.
- `DirectorRouter.lua`: request validation, unknown target rejection, expiration checks, target invocation, and final approval routing.
- `DirectorConflictResolver.lua`: deterministic arbitration hooks for priority, conflict groups, expiration, and performance overrides.
- `DirectorDecisionTrace.lua`: bounded decision trace history for every submitted, routed, resolved, cancelled, expired, or failed request.
- `DirectorContract.lua`: lower-case Director interface validation.
- `DirectorRequest.lua` and `DirectorApproval.lua`: structured constructors for request and approval payloads.
- `DirectorCapabilities.lua`, `DirectorHealth.lua`, `DirectorDiagnostics.lua`, `DirectorSignals.lua`, `DirectorConfig.lua`, and `DirectorTypes.lua`: support contracts, health, observability, configuration, and typed shapes.

## Foundation Director Tree

```text
DirectorCoordinator
-> Psychological Horror Director
-> Narrative Director
-> Story Director
-> Environment Director
-> Lighting Director
-> Audio Director
-> Music Director
-> Monster Director
-> Puzzle Director
-> Save Director
-> Difficulty Director
-> Performance Director
```

Foundation Directors expose capabilities and safe diagnostics, but they intentionally defer behavior. They do not move monsters, play sounds, darken lights, alter chapters, save data, or render client effects.

## Example Flow

```text
Observation: Player has been alone for 6 minutes.
-> Psychological Horror Director: tension is high.
-> Monster Director: reveal request submitted.
-> Lighting Director: darken corridor requested.
-> Coordinator: approves Lighting, defers Monster Reveal.
-> Reason: player has not yet reached intended narrative beat.
```

The Coordinator may allow atmosphere pressure while deferring major monster pressure until Narrative allows the beat.

## Authority Rules

- Directors are server-only.
- Directors may observe and request; they may not execute gameplay.
- Directors may not directly mutate each other.
- All cross-Director work goes through `DirectorCoordinator.submitRequest`.
- Every approval must include a status, reason, deciding Director, decision time, and diagnostics metadata.
- Every pending request must have an expiration.
- Failed Directors are isolated and reported through diagnostics.
- The Coordinator owns routing, pending request cleanup, health, diagnostics, snapshots, and decision traces.
