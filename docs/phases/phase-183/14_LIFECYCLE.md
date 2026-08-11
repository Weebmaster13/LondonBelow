# Lifecycle

Composition instances start in Created. Legal transitions are Created to Bound,
Bound to Resolving, Resolving to Resolved, Resolved to Active, Active to
Superseded, Superseded to Released, and Released to Closed. Cancellation and
failure states are explicit terminal-style alternatives.

Illegal lifecycle transitions reject and record stable failure evidence.

Shutdown blocks new definitions, composition creation, binding, compilation,
activation, supersession, and release while preserving inspectability.
