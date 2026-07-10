# Asset Governance Certification Integration Self-Checks

Executable self-checks verify that the certification integration runtime remains read-only and metadata-only.

Coverage includes provider consistency, snapshot consistency, diagnostic consistency, schema fields, enum validation, certified chain completeness, copied metadata isolation, Bootstrap ordering, Governance registration assumptions, documentation references, duplicate rejection, validation-before-mutation, bounded histories, snapshot isolation, diagnostics isolation, shutdown cleanup, namespace reset, runtime compatibility metadata, coordination metadata, and forbidden runtime surface absence.

Phase 65 self-checks currently execute 1,495 meaningful checks. Every check is expected to prove behavior, validation, isolation, boundedness, or declared metadata consistency.

The self-checks do not require remotes, services, DataStore, HTTP, MessagingService, Workspace, storage mutation, asset loading, orchestration, scheduling, gameplay, Presentation, Save, or Chapter content.
