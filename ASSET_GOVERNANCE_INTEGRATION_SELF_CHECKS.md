# Asset Governance Integration Self-Checks

Self-checks run before startup and verify the runtime remains read-only and metadata-only.

Coverage includes provider naming, snapshot kind naming, posture keys, valid registration for all four schemas, invalid schema rejection, enum validation, duplicate global id rejection, missing chain reference rejection, duplicate runtime name rejection inside a chain, duplicate expected order rejection inside a chain, unknown runtime/provider/coordinator rejection, the certified ten-runtime governance order, unsafe payload rejection, validation-before-mutation, bounded failure and snapshot histories, runtime limits, snapshot isolation, diagnostics isolation, shutdown cleanup, namespace reset, and banned runtime surface absence.

Executable self-checks are required before production certification.
