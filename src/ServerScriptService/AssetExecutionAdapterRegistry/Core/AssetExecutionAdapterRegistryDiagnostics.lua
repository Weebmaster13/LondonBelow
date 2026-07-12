--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrySerialization)
local State = require(script.Parent.AssetExecutionAdapterRegistryState)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetPlayback = true,
		noAnimationPlayback = true,
		noAudioPlayback = true,
		noUi = true,
		noVfx = true,
		noWorldMutation = true,
		noStorageMutation = true,
		noClientAuthority = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noPersistence = true,
		noHttp = true,
		noMessaging = true,
		noAnalytics = true,
		noTelemetry = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
	}
end

local function posture()
	return {
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
		assetExecutionAdapterRegistryDiagnosticsPosture = "diagnostics expose health-only copied metadata",
		assetExecutionAdapterRegistryBootstrapPosture = "Bootstrap dependency follows adapter runtime",
		assetExecutionAdapterRegistryGovernancePosture = "Governance snapshot provider is fixed",
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
	}
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	local report = {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		counts = counts,
		limitUsage = {
			registries = limitUsage(counts.registries, Types.Limits.MaxRegistries),
			registrations = limitUsage(counts.registrations, Types.Limits.MaxRegistrations),
			boundaries = limitUsage(counts.boundaries, Types.Limits.MaxRegistrationBoundaries),
			compatibilities = limitUsage(
				counts.compatibilities,
				Types.Limits.MaxRegistryCompatibilities
			),
			audits = limitUsage(counts.audits, Types.Limits.MaxRegistrationAudits),
			registrySnapshots = limitUsage(
				counts.registrySnapshots,
				Types.Limits.MaxRegistrySnapshots
			),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = Serialization.deepCopy(Types.GovernanceSnapshotProviders),
		noAuthorityPosture = noAuthorityPosture(),
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			registries = state.registries,
			registrations = state.registrations,
			boundaries = state.boundaries,
			compatibilities = state.compatibilities,
			audits = state.audits,
			registrySnapshots = state.registrySnapshots,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
	for key, value in pairs(posture()) do
		report[key] = value
	end
	return report
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
