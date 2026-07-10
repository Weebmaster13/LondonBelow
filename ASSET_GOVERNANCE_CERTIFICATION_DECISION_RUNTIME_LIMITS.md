# Asset Governance Certification Decision Runtime Limits

Runtime limits match `AssetGovernanceCertificationDecisionTypes.Limits` exactly.

- `MaxDecisions`: 120
- `MaxRequirements`: 520
- `MaxEvaluations`: 720
- `MaxAudits`: 320
- `MaxValidationFailures`: 260
- `MaxSnapshotHistory`: 70
- `MaxPayloadDepth`: 8
- `MaxPayloadNodes`: 540
- `MaxStringLength`: 300
- `MaxTags`: 36
- `MaxEvidence`: 64
- `MaxDecisionChildren`: 240

Validation rejects data that exceeds these limits before mutation. Bounded validation failures and snapshot history drop oldest entries after their limits are reached.

Limits only bound deterministic decision metadata. They do not create authorization, approval, rejection, repair, execution, orchestration, scheduling, persistence, networking, client authority, gameplay, Presentation, Save, or Chapter behavior.

Phase 75 integration-readiness declarations reuse the same serialization, evidence, tag, string, depth, and node limits. They are static copied metadata and do not create execution routing, dispatch, scheduler queues, repair queues, approval routing, authorization routing, orchestration, persistence, networking, gameplay, Presentation, Save, or Chapter behavior.

Phase 76 integration hardening does not change these limits. It adds exact ordering and deterministic declaration validation while continuing to reject oversized evidence, tags, metadata, strings, depth, and node counts before mutation.

Phase 77 execution-readiness declarations reuse the same serialization, evidence, tag, string, depth, and node limits. They do not add execution queues, dispatch targets, runtime handles, authorization tokens, asset handles, asset operations, gameplay, Presentation, Save, or Chapter behavior.
