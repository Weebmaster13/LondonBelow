# Cancellation And Compensation

Cancellation requires authorization and a reason. Unauthorized cancellation rejects. Cancelled workflows never resume.

Compensation is represented as command-request metadata only. The workflow layer does not execute compensation commands, mutate gameplay state, publish events, or access subsystem internals.

Future command execution remains owned by the Runtime Command Bus and authoritative domain handlers.
