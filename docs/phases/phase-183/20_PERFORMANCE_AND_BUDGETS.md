# Performance And Budgets

Phase 183 centralizes limits in `Types.VisualCompositionLimits`: definitions,
composition instances, nodes per definition, composition depth, layers,
regions, responsive variants, state variants, references per node, revision
history, evidence, and profiler records.

Compilation is deterministic and bounded. Plan history is bounded. Evidence and
profiler metadata are bounded.

No runtime work is per-frame. No RunService dependency, task spawning,
networking, rendering, or Roblox Instance mutation exists in this phase.
