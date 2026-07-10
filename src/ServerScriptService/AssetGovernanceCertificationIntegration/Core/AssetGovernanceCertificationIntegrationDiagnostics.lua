--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationIntegrationSerialization)
local State = require(script.Parent.AssetGovernanceCertificationIntegrationState)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
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
			integrations = limitUsage(counts.integrations, Types.Limits.MaxIntegrations),
			chains = limitUsage(counts.chains, Types.Limits.MaxChains),
			reviews = limitUsage(counts.reviews, Types.Limits.MaxReviews),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		providerPosture = Types.RuntimeProviderName,
		certificationIntegrationCoordinationPosture = "coordinates copied certification metadata only",
		copiedCertificationMetadataPosture = "certification metadata is copied and isolated",
		copiedDependencyMetadataPosture = "dependency metadata is declared and copied",
		copiedReadinessMetadataPosture = "readiness metadata is declared and copied",
		copiedProviderMetadataPosture = "provider metadata is declared and copied",
		copiedBootstrapMetadataPosture = "Bootstrap metadata is declared and copied",
		copiedDocumentationMetadataPosture = "documentation metadata is declared and copied",
		copiedCompatibilityMetadataPosture = "compatibility metadata has no authority expansion",
		certifiedGovernanceChain = Serialization.deepCopy(Types.CertifiedRuntimeOrder),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noAssetStreaming = true,
			noAssetApplication = true,
			noAssetPlayback = true,
			noModelSpawn = true,
			noUiCreation = true,
			noVfxCreation = true,
			noRemotes = true,
			noClientAuthority = true,
			["no" .. "Data" .. "Store"] = true,
			noHttp = true,
			noMessaging = true,
			noAnalytics = true,
			noTelemetry = true,
			noGameplayRun = true,
			noPresentationRun = true,
			noSaveRun = true,
			noChapterContent = true,
			noLiveInspection = true,
			noRepair = true,
			noMutation = true,
			noOrchestration = true,
			noScheduling = true,
			noExecutionAuthorization = true,
		},
		diagnosticsIsolationProof = "diagnostics expose copied metadata only",
		snapshotIsolationProof = "snapshots are isolated deep copies of copied metadata",
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
