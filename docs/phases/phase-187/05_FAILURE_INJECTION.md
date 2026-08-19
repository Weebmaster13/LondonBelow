# Phase 187 - Failure Injection

The Studio matrix must inject invalid contracts, creation/property failures, commit failure, stale revisions, attribute tampering, node detachment, and mount loss while proving last-good-tree preservation and cleanup.

## Ownership

Phase 187 owns the renderer failure-injection specification.

## Non-Ownership

It does not claim injected tests ran without evidence.

## Certification Boundary

Every required injected test must pass in the imported Studio result.
