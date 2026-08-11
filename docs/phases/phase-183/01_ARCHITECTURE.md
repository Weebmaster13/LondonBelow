# Phase 183 Architecture

The Roblox Visual Composition Runtime sits after Roblox Rendering Session
Runtime and before any future visual execution or Roblox Instance runtime. Its
provider and snapshot provider are both `robloxVisualCompositionRuntime`.

The runtime owns visual composition structure: definitions, instances, rooted
graphs, semantic nodes, layer metadata, region metadata, layout intent,
responsive variants, reference identifiers, accessibility semantics,
rendering-session binding, deterministic compilation, revisions, lifecycle,
diagnostics, snapshots, evidence, metrics, profiler metadata, budgets,
governance, and certification posture.

It does not own instantiation. A composition may say that a Dialogue layer has a
DialogueBody text node and ChoiceGroup, but it never says to call
`Instance.new`, mutate Roblox properties, load assets, or communicate with a
client.
