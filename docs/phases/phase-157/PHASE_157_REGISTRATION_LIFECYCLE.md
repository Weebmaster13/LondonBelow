# Registration Lifecycle

Registration validates the definition, resolves the family, registers the Phase 156 target, registers Phase 156 interactions for each action, then commits environmental state.

If target or interaction registration fails, rollback unregisters any Phase 156 target/interactions created by the environmental runtime.
