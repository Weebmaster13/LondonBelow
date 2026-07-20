# Transition Engine

`EnvironmentalTransitionRuntime.evaluate` produces a transition plan without mutating state. Commit occurs only inside the handler passed to Phase 156 `InteractionCoordinator.requestInteraction`.

Invalid transitions return stable reason codes.
