# Accessibility Diagnostics

Accessibility diagnostics expose:

- initialized
- started
- lifecycle state
- setting count
- visual rule count
- audio rule count
- input assist count
- motion comfort count
- readability count
- content warning count
- validation failure count
- snapshot count
- runtime limits
- serialization posture
- snapshot isolation proof
- no-execution posture
- last self-check result
- health state

Diagnostics are read-only copies and safe for Framework health checks. They do not apply client settings or final UI.

## Hardened Diagnostics

Diagnostics now expose enough evidence for production review without leaking mutable state:

- lifecycle state and health;
- per-category counts and limit usage;
- bounded sanitized validation failures;
- runtime limits;
- serialization posture;
- snapshot isolation proof;
- no-execution posture;
- last self-check result.

Validation failures are sanitized before diagnostics record them. Diagnostics must be used for health inspection only; they must not become player-facing UI, remote payloads, settings execution, input remapping, or effect execution.
