# Dialogue Definitions

Dialogue definitions are immutable after registration.

Required definition fields:

- dialogueId
- version
- participants
- entryNodeId
- variables
- conditions
- nodes
- metadata

Validation rejects unknown fields, duplicate dialogue ids, unsupported participant types, unsupported node types, duplicate nodes, missing entry nodes, unreachable nodes, duplicate variables, malformed choices, unsafe payload markers, oversized payloads, functions, threads, userdata, and Roblox Instances.
