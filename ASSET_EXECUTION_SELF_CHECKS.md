# Asset Execution Self-Checks

Executable self-checks verify provider identity, snapshot identity, runtime identity, schema validation, duplicate rejection, reference validation, invalid ids, unsupported fields, unsafe metadata, deep payload rejection, cyclic payload rejection, validation-before-mutation, diagnostics isolation, snapshot isolation, runtime-limit enforcement, shutdown cleanup, namespace reset, and banned runtime surface absence.

The self-checks intentionally treat execution as metadata only. Passing self-checks does not create asset loading, spawning, playback, routing, dispatch, queues, scheduler, orchestration, gameplay execution, Presentation execution, Save execution, Chapter behavior, remotes, or client authority.
