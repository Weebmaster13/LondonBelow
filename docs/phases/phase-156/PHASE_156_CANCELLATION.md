# Cancellation

`InteractionCoordinator.cancelSession` marks a session cancelled, records evidence, and releases contention. Unknown or invalid session ids reject.

Cancellation does not own animation, UI, save, inventory, or Workspace rollback.
