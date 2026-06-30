# London Engine Governance Review

This document records the 10000/10 audit and hardening pass for the London Engine Governance Layer.

Governance is not gameplay, Monster AI, Chapter 1, final UI, or final art. It is the enforcement layer that keeps London Engine aligned with the London Engine Constitution as the project grows.

## Reviewed Files

- `src/ServerScriptService/Core/Governance/EngineGovernance.lua`
- `src/ServerScriptService/Core/Governance/EngineContractTypes.lua`
- `src/ServerScriptService/Core/Governance/EngineContractRegistry.lua`
- `src/ServerScriptService/Core/Governance/EngineContractValidator.lua`
- `src/ServerScriptService/Core/Governance/DirectorContract.lua`
- `src/ServerScriptService/Core/Governance/ObservationContract.lua`
- `src/ServerScriptService/Core/Governance/ExecutionContract.lua`
- `src/ServerScriptService/Core/Governance/EngineScorecard.lua`
- `src/ServerScriptService/Core/Governance/GovernanceDiagnostics.lua`
- `src/ServerScriptService/Core/Governance/GovernanceSignals.lua`
- `src/ServerScriptService/Core/Framework.lua`
- `ENGINE_GOVERNANCE.md`
- `AGENTS.md`
- `LONDON_ENGINE.md`
- `ENGINE_CONSTITUTION.md`

## Issues Found

- Contract validation accepted too much implied architecture. Several important fields could be present but empty without producing a strong enough production-readiness signal.
- Contract issues only had broad severity. Governance could report problems, but it did not expose a clear health state for startup, diagnostics, or future dashboards.
- Scorecards were useful but too forgiving. A weak subsystem could receive acceptable category scores even without enough diagnostics, snapshot support, cleanup, multiplayer guarantees, or documented failure behavior.
- Built-in contracts were cloned with shallow copies for nested rule arrays. That created avoidable mutation risk if future code inspected and modified nested contract metadata.
- Documentation explained why Governance exists, but did not yet document health states, strict pass/fail behavior, or concrete weak-contract examples.

## Fixes Made

- Added explicit Governance health states: `NotValidated`, `Healthy`, `Warning`, and `Failed`.
- Expanded issue severity levels to include `Pass`, `Info`, `Warning`, `Error`, and `Fatal`.
- Added `ValidationSummary` so diagnostics and startup logs can expose fatal, error, warning, and info counts.
- Hardened contract shape validation with fatal schema checks for missing names, invalid owner layers, invalid status, malformed array fields, malformed rule tables, and invalid client presentation metadata.
- Strengthened production validation so production systems cannot pass with empty diagnostics, snapshot providers, cleanup behavior, multiplayer guarantees, failure modes, or documentation.
- Enforced that gameplay-truth systems must declare Observation Engine output unless they are core infrastructure, lobby orchestration, or portal launch flow.
- Enforced that major horror surfaces must declare Director approval rules unless they are Directors or Observation infrastructure.
- Enforced that Monster AI contracts cannot own horror pacing, scare selection, reveal timing, or climax control.
- Enforced that execution systems cannot invent pacing decisions.
- Enforced that remote-owning non-Core systems must depend on `RemoteManager`.
- Added stricter nested rule validation for observation IDs, approval rules, and execution permissions.
- Made scorecards stricter, issue-aware, and production useful with `passed` and `grade` fields.
- Added Governance startup validation summaries through the logger.
- Added Governance health capture to diagnostics and snapshots.
- Deep-cloned nested contract rule arrays in the registry.
- Updated `ENGINE_GOVERNANCE.md` with severity, health, stricter scoring, passing, weak, and failing examples.

## Remaining Risks

- Governance validates declared contracts. It does not statically scan every source file for direct remote creation, hidden client truth, or undocumented EventBus paths.
- Current built-in contracts are intentionally broad because they describe established major runtimes. Future mature subsystems should be narrower and more specialized.
- Warnings do not block startup. They are meant to force review before a subsystem grows, not to stop development on every architectural smell.
- Future source-level lint rules could catch forbidden calls more directly, such as creating remotes outside `RemoteManager` or calling Directors from ordinary gameplay systems.

## Future Codex Usage

Future Codex tasks should use Governance as part of subsystem design, not as an afterthought:

1. Read `LONDON_ENGINE.md`, `ENGINE_CONSTITUTION.md`, `AGENTS.md`, and `ENGINE_GOVERNANCE.md`.
2. Define the subsystem's owner layer and boundaries before implementing code.
3. Decide what observations the subsystem emits when it creates server truth.
4. Decide what Director approvals are required for horror, narrative, environment, audio, lighting, monster, puzzle, save, difficulty, or performance pressure.
5. Add diagnostics, snapshot support, cleanup, multiplayer guarantees, failure modes, and documentation.
6. Register or update the subsystem contract through `EngineGovernance`.
7. Run validation and treat `Error` or `Fatal` issues as blockers.

## Registering A New Subsystem Correctly

A correct subsystem contract must answer these questions:

- What is the system name?
- Which owner layer owns it?
- Is it `Foundation`, `Production`, `Experimental`, or `Deprecated`?
- What does it own?
- What does it explicitly not own?
- What systems does it depend on?
- What observations does it emit?
- What Director approvals does it require?
- What execution permissions does it need?
- What, if anything, may the client present?
- What diagnostics can developers inspect?
- What snapshots can debugging tools capture?
- How does it clean up tasks, state, instances, and connections?
- What makes it multiplayer-safe?
- How does it fail safely?
- Where is it documented?

Production systems must not leave diagnostics, snapshots, cleanup, multiplayer guarantees, failure modes, or documentation empty.

## Server Authority Rules

- Clients may request actions and present approved effects.
- Clients never own gameplay truth, observations, Director approvals, party truth, portal truth, monster truth, save truth, objective truth, or checkpoint truth.
- Gameplay systems that create truth must emit observations.
- Directors interpret observations and produce approvals or decisions.
- Execution systems execute approved decisions and emit observations when they create new truth.
- Monster AI owns physical movement and tactical behavior, not horror pacing.

## How Governance Protects The 100000/10 Standard

Governance forces architecture to be declared before systems become large. It makes missing boundaries, missing cleanup, missing diagnostics, unsafe client authority, missing observations, missing Director approvals, and responsibility drift visible in structured data.

This protects London Engine from becoming a collection of unrelated Roblox scripts. Every future subsystem must prove where it belongs, what it owns, what it refuses to own, how it can be inspected, how it fails, and how it fits the Golden Flow.

