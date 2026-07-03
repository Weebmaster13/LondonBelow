# Runtime Graph Runtime Limits

Runtime Graph state is bounded by design.

Limits cover runtime nodes, dependency edges, capabilities, requirements, compatibility records, ordering records, startup plans, shutdown plans, groups, graph validation records, validation failures, snapshot history, payload depth, payload nodes, payload string length, tags per schema, plan node counts, group node counts, plan dependencies, and plan orderings.

Limit failures reject before state mutation. Hitting a limit does not evict source-of-truth schemas, start or stop anything, rebuild the graph, call Framework, or mutate live runtime state.
