# Horror Orchestration Audit

This audit reviewed Phase 15.5 as a production coordination layer, not a gameplay or scare execution system.

## Reviewed

- `HorrorOrchestrator`
- Core orchestration config, state, validation, diagnostics, signals, and types
- Pressure request creation, validation, queueing, and routing
- Pressure, silence, release, escalation, scare eligibility, chase preparation, and emotional beat models
- Sensory, monster, environment, gameplay, and narrative coordination bundles
- Simulator and self-checks
- Governance contract, Bootstrap registration, Rojo mapping, docs, roadmap, tasks, and London Bible integration notes

## Issues Found

- Pressure decayed only through a helper and was not called by scheduled cleanup.
- Seen request IDs were retained until shutdown and needed a hard bound.
- Release decisions could be preempted by silence in some high-pressure cases.
- Coordination bundle payloads used command-like field names.
- Self-checks asserted puzzle protection, overload suppression, and no execution instead of proving them from actual bundles.
- Diagnostics did not expose suppression reasons, release reasons, scare eligibility summaries, bundle count, or seen request limits.

## Fixes Made

- Scheduled cleanup now expires queued requests and decays pressure.
- Pressure deltas are clamped per request and total pressure remains clamped from 0 to 100.
- Seen request IDs are bounded by `MaxSeenRequestIds`.
- Safe-room and puzzle-room scare suppression now wins before release/escalation logic.
- Coordination bundle entries now use `recommendation`, are stamped `approvalOnly = true`, and explicitly set `executionAllowed = false`.
- Bundle validation rejects any item that is not approval-only or contains execution-like fields.
- Self-checks now prove silence, release, safe-room suppression, puzzle protection, overload suppression, duplicate rejection, expired rejection, approval-only bundles, and shutdown cleanup.
- Self-checks now explicitly prove that scare candidates without narrative or emotional meaning are suppressed.
- Diagnostics now expose suppression reasons, release reasons, scare eligibility results, bundle count, request-id limits, counters, queue size, validation failures, and health.

## Remaining Risks

- Future DirectorCoordinator handoff is still conceptual; this phase intentionally does not submit live Director requests.
- Future Monster AI must still be audited to ensure it consumes orchestration decisions without deciding intent.
- Future presentation systems must treat bundles as recommendations, not commands.

## Authority Confirmation

Horror Orchestration remains server-only, approval-only, and execution-free.

## Second-Pass Audit Note

The follow-up audit added `HORROR_PRESSURE_MODEL_REVIEW.md` and strengthened self-check evidence for meaningless scare rejection so every requested production proof has a direct scenario.
