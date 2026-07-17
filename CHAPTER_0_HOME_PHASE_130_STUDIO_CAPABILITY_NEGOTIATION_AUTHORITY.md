# Chapter 0 Home Phase 130 Studio Capability Negotiation Authority

Phase 130 creates `automation/studio-capability-negotiation-authority.mjs`, the
sole repository authority for negotiating advertised Studio MCP capabilities.

The Phase 129 Integration Contract defines the static protocol. Phase 130 validates
what a specific external implementation advertises, resolves dependencies,
detects conflicts, freezes negotiated profiles, publishes diagnostics, and records
an immutable audit.

This phase does not execute Studio, discover sessions, invoke runners, certify
results, implement networking transport, capture structured results, write
persistence, or mutate gameplay.

## Ownership

The authority owns capability advertisement validation, required capability
validation, optional capability negotiation, deprecated capability rejection,
dependency validation, conflict detection, compatibility negotiation, immutable
profile publication, diagnostics, audit, version compatibility, lifecycle, and
capability publication.

It does not own protocol definition, Studio execution, runner execution, session
discovery, activation, binding, certification, gameplay, persistence, rendering,
networking transport, runtime evidence, or structured capture.

## Lifecycle

Success path:

`Idle -> ReceiveAdvertisement -> ValidateAdvertisement -> ResolveDependencies -> ResolveConflicts -> FreezeProfile -> NegotiationComplete`

Failure paths:

- `ReceiveAdvertisement -> AdvertisementRejected`
- `ValidateAdvertisement -> UnsupportedCapability`
- `ResolveDependencies -> DependencyFailure`
- `ResolveConflicts -> ConflictFailure`
- `FreezeProfile -> FreezeRejected`

No skipped, cyclic, or undocumented transitions are accepted.

## Advertisement Schema

Every capability advertisement contains exactly:

- `capabilityId`
- `capabilityVersion`
- `category`
- `provider`
- `required`
- `optional`
- `dependencies`
- `conflicts`
- `status`

Unknown fields reject. Duplicate identifiers reject. Deprecated capabilities
reject. Capability identities are frozen.

## Categories

Supported categories are `Session`, `Execution`, `Evidence`, `Diagnostics`,
`Protocol`, `Validation`, `Compatibility`, and `Serialization`.

## Required Capabilities

The mandatory capability set remains:

- `SessionIdentity`
- `RunnerExecution`
- `StructuredResults`
- `EvidenceTransport`
- `Heartbeat`
- `VersionMetadata`

Missing mandatory capabilities reject negotiation.

## Optional Capabilities

Optional capabilities are `ExtendedDiagnostics`, `PerformanceMetrics`,
`CompatibilityExtensions`, and `FutureProtocolExtensions`. Optional capabilities
never silently become mandatory.

## Dependency Model

Dependency validation detects missing dependencies, circular dependencies,
incompatible dependency versions, deprecated dependencies, and duplicate
dependencies. Every dependency failure is deterministic.

## Conflict Model

Declared conflicts are rejected with deterministic diagnostics. Conflicts are not
resolved implicitly.

## Negotiated Profiles

Successful negotiation freezes immutable `ProtocolProfile`, `ExecutionProfile`,
`EvidenceProfile`, `DiagnosticsProfile`, `ValidationProfile`, and
`CompatibilityProfile` records. Profiles cannot mutate after publication.

## Diagnostics And Audit

Diagnostics include protocol version, contract version, negotiation version,
required capabilities, optional capabilities, negotiated capabilities, rejected
capabilities, dependency resolution, conflict resolution, compatibility state,
negotiation state, failure reason, and timestamp.

Audit entries include negotiation id, advertisement id, authority id, profile id,
state, reason, timestamp, and contract version. Audit history is append-only and
duplicates reject.

## Current Result

No connected Studio MCP session identity is visible and no external implementation
has advertised a conforming capability set. The repository continues to report
`SESSION_NOT_VISIBLE`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 130 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.
