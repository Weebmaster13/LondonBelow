# Asset Execution Adapter Readiness Self-Checks

Phase 95 expands Asset Execution Runtime self-checks for adapter readiness.

Coverage includes:

- provider name consistency
- exact 38-declaration count
- exact schema terminology and field order
- `readinessKind` validation
- `readinessStatus` validation
- `adapterKind` validation
- `adapterAuthorityKind` validation
- `adapterBoundaryKind` validation
- `assetOperationBoundaryKind` validation
- `lifecycleBoundaryKind` validation
- declaration deletion, insertion, replacement, reversal, and reordering rejection
- order-table shape and name validation
- copied evidence exactness
- copied tag exactness
- copied metadata exactness
- future adapter absence
- asset-operation absence
- diagnostics isolation
- snapshot isolation
- lowerCamelCase posture keys
- shutdown cleanup regression coverage
- banned runtime surface absence

The self-checks do not execute adapter behavior. They prove the runtime remains metadata-only.

