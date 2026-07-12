# Asset Execution Self-Checks

Executable self-checks verify provider identity, snapshot identity, runtime identity, schema validation, duplicate rejection, reference validation, invalid ids, unsupported fields, unsafe metadata, schema drift, enum drift, deep payload rejection, cyclic payload rejection, readiness child references, same-runtime audit integrity, ordered child arrays, failed validation no mutation, validation-before-mutation, diagnostics health-only behavior, diagnostics isolation, snapshot isolation, lowerCamelCase posture keys, runtime-limit enforcement, signal boundary, coordinator API boundary, shutdown cleanup, namespace reset, and banned runtime surface absence.

The self-checks intentionally treat execution as metadata only. Passing self-checks does not create asset loading, spawning, playback, routing, dispatch, queues, scheduler, orchestration, gameplay execution, Presentation execution, Save execution, Chapter behavior, remotes, or client authority.

Phase 92 expands meaningful deterministic coverage beyond Phase 91 by checking exact Type-table identity, exact runtime limits, signal metadata consistency, coordinator metadata API consistency, cross-runtime audit rejection, ordered child arrays, snapshot posture isolation, diagnostics posture isolation, and additional nested forbidden-marker payload paths.
