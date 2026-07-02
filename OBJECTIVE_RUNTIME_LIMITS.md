# Objective Runtime Limits

Objective Runtime is bounded by design.

- Objectives are capped.
- Tasks, requirements, dependencies, and progress records are capped.
- Tags are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, and string length are capped.

Source-of-truth schema categories reject once full instead of silently evicting objective state.

## Limit Behavior

Objective, task, requirement, dependency, and progress limits reject new source-of-truth records once full. Validation failure and snapshot histories remain bounded rolling histories because they are observability records, not objective truth.
