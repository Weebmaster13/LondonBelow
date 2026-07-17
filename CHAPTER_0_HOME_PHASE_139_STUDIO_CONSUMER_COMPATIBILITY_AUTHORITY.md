# Chapter 0 Home Phase 139 Studio MCP Consumer Compatibility Authority

Phase 139 adds the repository-owned Studio MCP Consumer Compatibility Authority in
`automation/studio-consumer-compatibility-authority.mjs`.

## Mission

The authority evaluates a deterministic repository fixture representing a future
consumer declaration against the Phase 137 external consumer contract, the Phase
138 recognized consumer manifest, the Phase 136 external execution boundary, and
upstream protocol and capability declarations.

The evaluation is repository metadata only. It does not prove a consumer exists,
is connected, is authenticated, is reachable, or may execute.

## Ownership

The authority owns evaluation identity, versioning, candidate-profile intake,
lifecycle validation, component compatibility evaluation, manifest recognition
evaluation, compatibility result publication, diagnostics, audit, and
incompatibility reason classification.

It does not own Phase 137 compatibility policy, Phase 138 manifest declarations,
contract construction, manifest construction, consumer discovery, external
identity resolution, network reachability, authentication, authorization,
credential material, transport, MCP communication, Studio execution, Runner
invocation, dispatch transmission, ownership transfer, acknowledgement receipt,
result receipt, runtime evidence, certification, gameplay, persistence,
rendering, analytics, or telemetry.

## Separation From Phases 137 And 138

Phase 137 defines compatibility policy. Phase 138 defines recognized consumer
manifest declarations. Phase 139 evaluates a candidate profile against those
read-only definitions and never rewrites either source.

## Candidate Profile

The deterministic repository fixture contains exactly `candidateProfileId`,
`candidateProfileVersion`, `consumerType`, `consumerContractVersion`,
`protocolVersion`, `dispatchVersion`, `boundaryVersion`,
`capabilityProfileVersion`, `supportedAcknowledgementSchemaVersion`,
`supportedResultSchemaVersion`, `supportedEvidenceSchemaVersion`,
`supportedFailureSchemaVersion`, `declaredManifestId`, and `timestamp`.

Unknown fields, missing fields, unsupported consumer types, unsupported versions,
duplicate identities, and mutable candidate profiles reject. The fixture is not
a connected consumer.

## Lifecycle

Success path:

`Idle -> ReceiveCandidateProfile -> ValidateCandidateSchema ->
ResolveContractRequirements -> ResolveManifestRecognition ->
EvaluateCompatibility -> FreezeEvaluation -> CompatibilityPublished`

Failure paths are `MissingCandidateProfile`, `CandidateRejected`,
`ContractResolutionFailed`, `ManifestResolutionFailed`,
`CompatibilityInconclusive`, and `FreezeRejected`.

## Evaluation Schema

Published evaluations contain exactly `evaluationId`, `evaluationVersion`,
`candidateProfileId`, `consumerContractId`, `consumerContractVersion`,
`manifestId`, `manifestVersion`, `consumerType`, eight component evaluations,
`manifestRecognitionEvaluation`, `overallCompatibility`,
`consumerAvailabilityState`, `executionEligibility`, `validationState`, and
`timestamp`.

Component evaluations contain exactly `requiredVersion`, `declaredVersion`,
`evaluationResult`, and `reasonCode`. Manifest recognition evaluations contain
exactly `manifestId`, `consumerType`, `consumerStatus`, `matrixResult`,
`evaluationResult`, and `reasonCode`.

Normal Phase 139 output is `CompatibleDefinition`, `CandidateDeclared`, and
`DefinitionCompatibleButUnavailable`.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. Boundary
eligibility remains `Blocked`; ownership remains `RepositoryOwned`;
`runnerInvoked = false`; `structuredResultCaptured = false`; no transport,
runtime evidence, connected consumer, or certification decision is produced.

## Acceptance Criteria

- `npm run london:studio:compatibility:phase139:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 138 through Phase 132 regression self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
