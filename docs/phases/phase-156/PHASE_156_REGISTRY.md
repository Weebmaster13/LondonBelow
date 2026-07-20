# Registry

`InteractionObjectRuntime` stores bounded interaction definitions, targets, intents, locks, cooldowns, sessions, evidence, validation failures, and snapshot history.

All public registration flows go through `InteractionCoordinator`, which records validation failures without mutating accepted state.
