# Composition Compiler

The compiler turns a normalized definition, composition instance, binding, and
revision into an immutable resolved composition plan. The plan contains ordered
nodes, layers, regions, layout intent, state metadata, binding metadata,
accessibility metadata, and reference metadata.

Compilation is plan-first. It does not mutate active visual state incrementally
and does not create Roblox Instances.

Identical valid input produces structurally identical output. This determinism
is required for the future Phase 184 diff runtime.
