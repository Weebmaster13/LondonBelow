# Contention

Non-replayable interactions reserve an active session during execution. A concurrent request is rejected with `ContentionBlocked`.

Contention is released on completion, failure, or cancellation.
