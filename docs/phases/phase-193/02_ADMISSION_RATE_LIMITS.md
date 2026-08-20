# Phase 193 - Admission and Rate Limits
## Ownership
Validated requests enter a one-second bounded admission window capped at 128 starts. Each target node may own at most 16 active animations, while the global Phase 192 cap remains 64.
## Non-Ownership
Admission does not queue, retry, or reorder rejected work.
## Certification Boundary
Studio must prove exact boundary acceptance, flood rejection, reset, and recovery.
