# Command Bus Runtime

`RuntimeCommandBus.lua` owns command submission, batch submission, cancellation, deterministic dispatch, inspection, snapshots, validation, shutdown cleanup, idempotency protection, and successful-command Event Bus publication.

It is runtime-local and server-authoritative. It is not networking, persistence, gameplay execution, presentation execution, or save serialization.
