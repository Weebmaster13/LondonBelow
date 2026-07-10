# Asset Governance Integration Self-Checks

Self-checks run before startup and verify the runtime remains read-only and metadata-only.

Coverage includes:

- provider consistency
- snapshot consistency
- diagnostic posture consistency
- exact schema field surfaces
- exact enum cardinality and values
- valid registration for all four schemas
- nil and non-table rejection
- invalid id rejection
- required field rejection
- unsupported enum rejection
- duplicate global id rejection
- missing chain reference rejection
- duplicate runtime name rejection inside a chain
- duplicate expected order rejection inside a chain
- unknown runtime/provider/coordinator rejection
- mismatched runtime/provider/coordinator/order rejection
- certified ten-runtime governance order
- runtime limit constants
- payload depth and node limits
- cycle rejection
- function, thread, userdata, and Instance-shaped table rejection
- unsafe metadata, tags, and findings rejection
- validation-before-mutation
- bounded validation failures
- bounded snapshot history
- snapshot isolation
- diagnostics isolation
- shutdown cleanup
- namespace reset
- count reset
- documentation reference consistency
- Bootstrap dependency order consistency
- forbidden runtime surface absence

Executable self-checks are required before production certification. Phase 60 targets a broad deterministic suite without adding artificial checks.
