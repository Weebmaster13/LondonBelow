# TRIGGER RUNTIME LIMITS

Trigger Runtime enforces explicit limits for triggers, categories, sources, targets, events, filters, conditions, dependencies, groups, outcomes, audits, validation failures, snapshots, payload depth, payload nodes, string length, tags, group members, and audit findings. Hitting a limit rejects safely before mutation.

## Production Hardening

Production hardening: all category limits, group member limits, audit finding limits, payload limits, validation failure history, and snapshot history are bounded. Hitting a limit rejects safely before mutation and never executes triggers, dispatches events, calls listeners, invokes callbacks, evaluates conditions, calls Rule Engine, calls Event Graph, calls Scheduler, creates remotes, or mutates Workspace.
