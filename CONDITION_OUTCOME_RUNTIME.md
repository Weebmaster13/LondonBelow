# Condition Outcome Runtime

Condition outcomes describe possible future results: Pass, Fail, Unknown, Deferred, or FutureOutcome.

Outcomes are possible future results, not computed facts. This runtime never decides whether an outcome is true, never triggers a result, never completes objectives, and never influences horror pacing.

Outcome records must reference registered conditions and remain safe, bounded, serializable, and server-owned.

## Production Hardening

Outcomes reject unsupported schema types, unsupported outcome kinds, invalid condition references, unsafe payloads, computed result markers, gameplay result markers, execution markers, callbacks, services, remotes, client markers, Workspace markers, and Chapter content. Outcomes are possible future results only.
