# Performance Budget Runtime Schemas

Budget schemas describe future performance boundaries for CPU, memory, network, render, and runtime categories.

Budget records require:

- `budgetId`;
- `ownerSystem`;
- optional `schemaType = PerformanceBudgetSchema`;
- optional `metadata`;
- optional `context`;
- optional `tags`.

Budgets are not measurements. They do not read live frame time, memory, network activity, render load, or gameplay state. They are stable schema records that future governed systems can reference when deciding whether work should be allowed.
