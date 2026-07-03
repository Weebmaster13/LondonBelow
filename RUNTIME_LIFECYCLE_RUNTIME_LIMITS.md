# Runtime Lifecycle Runtime Limits

Runtime Lifecycle state is bounded by design.

Limits cover lifecycle states, transitions, policies, guards, events, failures, recoveries, checkpoints, audits, compatibility records, validation failures, snapshots, payload depth, payload nodes, payload string length, tags per schema, policy refs, guard refs, and audit findings.

Limit failures reject before state mutation. Hitting a limit does not evict source-of-truth schemas, start or stop anything, trigger recovery, mutate live runtime state, or call Framework.
