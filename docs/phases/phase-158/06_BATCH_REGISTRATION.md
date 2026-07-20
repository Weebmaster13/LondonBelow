# Batch Registration

Chapter 0 fixtures are registered as a batch through `EnvironmentalInteractionCoordinator.registerDefinitions`.

If any fixture fails registration, already registered fixtures from that batch are unregistered in reverse order. The batch response records the failing fixture and the rollback result.

This preserves validation-before-mutation posture and prevents partial Chapter 0 environmental readiness.
