# Runtime Lifecycle Runtime Limits

Runtime Lifecycle state is bounded by design.

Limits cover lifecycle states, transitions, policies, guards, events, failures, recoveries, checkpoints, audits, compatibility records, validation failures, snapshots, payload depth, payload nodes, payload string length, tags per schema, policy refs, guard refs, and audit findings.

Limit failures reject before state mutation. Hitting a limit does not evict source-of-truth schemas, start or stop anything, trigger recovery, mutate live runtime state, or call Framework.

## Certified Limits

The runtime enforces `MaxLifecycleStates`, `MaxTransitions`, `MaxPolicies`, `MaxGuards`, `MaxEvents`, `MaxFailures`, `MaxRecoveries`, `MaxCheckpoints`, `MaxAudits`, `MaxCompatibilityRecords`, `MaxValidationFailures`, `MaxSnapshotHistory`, `MaxPayloadDepth`, `MaxPayloadNodes`, `MaxPayloadStringLength`, `MaxTagsPerSchema`, `MaxPolicyRefs`, `MaxGuardRefs`, and `MaxAuditFindings`.

Every category limit rejects safely before mutation. Limit failures do not evict schemas, start or stop runtimes, retry recovery, restore state, disable systems, mutate live lifecycle state, call Framework, load modules, or perform service resolution.
