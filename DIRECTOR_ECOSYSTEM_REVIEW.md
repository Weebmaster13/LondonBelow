# Director Ecosystem Review

This audit reviewed the Phase 7 Director Ecosystem Foundation as a long-lived London Engine API, not as gameplay content.

## Reviewed

- `DirectorCoordinator`
- `DirectorTypes`
- `DirectorConfig`
- `DirectorContract`
- `DirectorRegistry`
- `DirectorRouter`
- `DirectorRequest`
- `DirectorApproval`
- `DirectorCapabilities`
- `DirectorConflictResolver`
- `DirectorDecisionTrace`
- `DirectorHealth`
- `DirectorDiagnostics`
- `DirectorSignals`
- Bootstrap and Framework registration
- Governance contract for `Director Ecosystem Foundation`
- `DIRECTOR_*.md` documentation
- `LONDON_ENGINE.md`

## Issues Found

- Request validation accepted unknown priorities and did not validate the contents of string arrays.
- Target Directors could return malformed approvals and still enter the decision trace.
- Director contract validation only checked for method names and a Director name.
- Conflict resolver state could retain stale conflict groups until replaced.
- Diagnostics exposed pending count but not pending request IDs.
- Self-checks covered only the basic happy path, unknown target, expiration, cancellation, and trace presence.

## Fixes Made

- Added strict request validation for priorities, timestamps, observation IDs, tags, and conflict groups.
- Added `DirectorApproval.validate` and made `DirectorRouter` reject invalid target approvals.
- Strengthened `DirectorContract` to require display names, responsibilities, boundaries, capabilities, request kinds, and passing Director self-validation.
- Hardened conflict resolution with expired conflict pruning and replacement metrics.
- Added final decision trace entries for Coordinator-expired requests.
- Added pending request IDs to diagnostics snapshots.
- Hardened Director health summarization against malformed health responses.
- Expanded self-checks to cover malformed requests, target failure isolation, invalid approvals, and conflict-group deferral.
- Updated docs to reflect stricter validation and approval trust rules.

## Remaining Risks

- Foundation Directors intentionally defer real behavior; future specialized Directors must add domain-specific fairness logic.
- Conflict resolution is deterministic but still policy-light. Narrative, performance, accessibility, and multiplayer fairness constraints should be layered in as real Directors mature.
- Self-checks are runtime validation helpers, not a full automated test suite.
- The ecosystem does not yet enforce every future execution-system contract at runtime; Governance defines those boundaries for later phases.

## Future API Guidance

- Future Directors must use the lower-case interface in `DIRECTOR_CONTRACTS.md`.
- Requests must be created through `DirectorRequest.create` unless a test needs a hand-built expired request.
- Execution systems must not act on requests directly; they must consume approved decisions only.
- Monster AI must ask for permission through the Monster Director and must not own horror pacing.
- Environment, Lighting, Audio, and Music Directors coordinate through requests and approvals, not direct requires.

## Validation Checklist

- Valid request routes to a known Director.
- Unknown target is rejected.
- Expired valid request returns `Expired`.
- Malformed request is rejected without throwing.
- Failing Director is isolated.
- Invalid target approval is rejected.
- Lower-priority conflict-group request is deferred.
- Diagnostics expose health, capabilities, traces, pending requests, failures, and conflicts.
