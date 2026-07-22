# Lifecycle And Dependencies

The capability lifecycle is:

`Created -> Registered -> Validated -> Initialized -> Ready -> Running -> Suspended -> Shutdown`

`CapabilityDependencyGraph` validates:

- dependency existence;
- required interface existence;
- dependency graph cycle absence.

Dependency validation runs before activation. Suspension and recovery record evidence without recreating gameplay state.
