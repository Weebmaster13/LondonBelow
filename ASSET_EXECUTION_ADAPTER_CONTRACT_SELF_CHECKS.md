# Asset Execution Adapter Contract Self-Checks

Phase 97 expands Asset Execution Runtime self-checks for adapter-contract readiness.

Coverage includes:

- exact 24-declaration count
- exact field order
- provider identity
- snapshot identity
- coordinator identity
- Governance identity
- Bootstrap dependency
- contract enum validation
- lifecycle, authority, operation, serialization, and validation boundary enum validation
- declaration deletion, insertion, replacement, reversal, and rotation rejection
- duplicate id rejection
- sparse-array rejection
- dictionary-shaped array rejection
- unsupported field rejection
- unsupported order-table rejection
- whitespace drift rejection
- punctuation drift rejection
- metadata, evidence, and tag drift rejection
- nested payload contamination rejection
- diagnostics isolation
- snapshot isolation
- failed-validation no-mutation proof
- shutdown cleanup and namespace reset regression coverage

The self-checks do not execute adapter behavior. They prove the contract remains copied metadata only.

