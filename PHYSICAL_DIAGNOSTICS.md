# Physical Diagnostics

`PhysicalDiagnostics` exposes health and state for Physical Runtime.

## Exposed Fields

- initialized
- started
- registered object count
- reservation count
- ownership count
- transform count
- validation failures
- snapshot count
- runtime limits
- health
- serialization posture
- last self-check result
- snapshot isolation proof

## Rules

Diagnostics are read-only returned copies. They never expose unsafe runtime values or Roblox Instances.
