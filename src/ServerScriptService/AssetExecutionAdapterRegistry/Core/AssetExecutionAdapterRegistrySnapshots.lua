--!strict

local State = require(script.Parent.AssetExecutionAdapterRegistryState)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetSpawning = true,
		noAssetPlayback = true,
		noClientAuthority = true,
		noNetworking = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
	}
end

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = Types.SnapshotKind,
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		runtimeLimits = dependencies.Serialization.deepCopy(Types.Limits),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = dependencies.Serialization.deepCopy(
			Types.GovernanceSnapshotProviders
		),
		noAuthorityPosture = noAuthorityPosture(),
		assetExecutionAdapterRegistryRuntimePosture = "registry stores copied metadata records only",
		assetExecutionAdapterRegistryValidationPosture = "validation occurs before mutation",
		assetExecutionAdapterRegistryRegistrationPosture = "registrations catalog adapters only",
		assetExecutionAdapterRegistryOwnershipPosture = "ownership is copied metadata only",
		assetExecutionAdapterRegistryCompatibilityPosture = "compatibility records are metadata only",
		assetExecutionAdapterRegistryBoundaryPosture = "boundaries prohibit executable surfaces",
		assetExecutionAdapterRegistryAuditPosture = "audits summarize copied registration metadata",
		assetExecutionAdapterRegistrySnapshotPosture = "registry snapshot records are metadata only",
		assetExecutionAdapterRegistryCertificationPosture = "registry foundation is non-executing",
		assetExecutionAdapterRegistrySchemaPosture = "schema fields are exact and closed",
		assetExecutionAdapterRegistryEnumPosture = "enum values are exact and closed",
		assetExecutionAdapterRegistryReferencePosture = "references are parent checked before mutation",
		assetExecutionAdapterRegistryArrayPosture = "child arrays are ordered and duplicate free",
		assetExecutionAdapterRegistryLimitPosture = "runtime limits match certified values",
		assetExecutionAdapterRegistryRuntimeLimitPosture = "runtime-limit metadata is exact",
		assetExecutionAdapterRegistryDiagnosticsPosture = "snapshots expose copied metadata only",
		assetExecutionAdapterRegistryBootstrapPosture = "Bootstrap dependency follows adapter runtime",
		assetExecutionAdapterRegistryGovernancePosture = "Governance snapshot provider is fixed",
		assetExecutionAdapterRegistryHardeningPosture = "production hardening freezes registry surfaces",
		assetExecutionAdapterRegistryIdentityPosture = "runtime identities reject aliases and casing drift",
		assetExecutionAdapterRegistryOrderingPosture = "schema, child, and provider ordering are fixed",
		assetExecutionAdapterRegistryMetadataPosture = "metadata remains serializable and non-executable",
		assetExecutionAdapterRegistryEvidencePosture = "evidence arrays remain ordered copied ids",
		assetExecutionAdapterRegistryTagPosture = "tag arrays remain ordered copied ids",
		assetExecutionAdapterRegistryNoImplementationPosture = "implementation records are not stored",
		assetExecutionAdapterRegistryNoActivationPosture = "activation is not exposed",
		assetExecutionAdapterRegistryNoExecutionPosture = "registered adapters are never called",
		assetExecutionAdapterRegistryNoOperationPosture = "no asset operation surface is present",
		assetExecutionAdapterRegistryNoAuthorityPosture = "registry metadata grants no authority",
		noExecution = true,
		noAssetLoading = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noNetworking = true,
		noAnalytics = true,
		noTelemetry = true,
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			registries = state.registries,
			registrations = state.registrations,
			boundaries = state.boundaries,
			compatibilities = state.compatibilities,
			audits = state.audits,
			registrySnapshots = state.registrySnapshots,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
