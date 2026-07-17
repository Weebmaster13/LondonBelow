# Chapter 0 Home Phase 138 Studio MCP External Consumer Manifest Authority

Phase 138 adds the repository-owned Studio MCP External Consumer Manifest
Authority in `automation/studio-external-consumer-manifest-authority.mjs`.

## Mission

The authority defines which future external Studio MCP consumer definitions this
repository officially recognizes. It consumes the Phase 137 consumer contract
authority read-only and publishes an immutable manifest, diagnostics, and audit.

## Ownership

The authority owns manifest identity, manifest versioning, lifecycle, supported
consumer catalog, supported protocol declarations, supported contract
declarations, compatibility catalog, publication, diagnostics, audit, and
evolution policy.

It does not own contracts, execution, dispatch, boundary, runtime, networking,
consumer connection, authentication, Studio execution, Runner invocation,
transport, acknowledgements, structured results, runtime evidence, certification,
gameplay, or persistence.

## Lifecycle

Success path:

`Idle -> ReceiveConsumerContract -> ValidateManifest -> BuildManifest ->
FreezeManifest -> ManifestPublished`

Failure paths are `MissingConsumerContract`, `ManifestRejected`,
`ManifestConstructionFailed`, and `FreezeRejected`. Illegal transitions, skipped
transitions, cycles, and terminal mutation reject.

## Manifest Schema

Published manifests contain exactly `manifestId`, `manifestVersion`,
`consumerContractId`, `consumerContractVersion`, `consumerType`,
`supportedProtocolVersions`, `supportedDispatchVersions`,
`supportedBoundaryVersions`, `supportedCapabilityProfiles`,
`compatibilityMatrix`, `validationState`, and `timestamp`.

Unknown fields, missing fields, duplicate identifiers, unsupported consumer
types, unsupported versions, invalid catalog entries, and invalid compatibility
matrix entries reject.

## Consumer Catalog

Catalog entries contain exactly `consumerId`, `consumerType`,
`supportedContractVersion`, `supportedProtocolVersion`,
`minimumCapabilityVersion`, and `status`. Allowed status values are `Defined`,
`Deprecated`, and `Retired`. Normal Phase 138 output uses `Defined`.

## Compatibility Matrix

Matrix entries contain exactly `protocolVersion`, `contractVersion`,
`boundaryVersion`, `dispatchVersion`, `minimumCapabilityVersion`, and
`compatibilityResult`. Allowed results are `Compatible` and `Incompatible`.
Normal Phase 138 output uses `Compatible`, meaning only that the repository
recognizes the definition. It does not mean a consumer exists or execution may
occur.

## Diagnostics And Audit

Diagnostics expose manifest version, manifest state, consumer availability
state, compatibility state, validation state, failure reason, and timestamp.
Normal output preserves `ContractOnly` and `DefinitionCompatible`.

Audit entries contain manifest ID, consumer contract ID, authority ID, manifest
state, compatibility state, validation state, and timestamp. Audit data is
append-only, immutable, and deterministic.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. Phase 138
preserves `SESSION_NOT_VISIBLE`, `runnerInvoked = false`,
`structuredResultCaptured = false`, no runtime evidence, no Studio execution, no
Runner invocation, no transport, no consumer discovery, and no certification
decision.

## Acceptance Criteria

- `npm run london:studio:manifest:phase138:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 137 through Phase 132 regression self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
