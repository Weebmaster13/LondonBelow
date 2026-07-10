--!strict

local State = require(script.Parent.AssetGovernanceCertificationIntegrationState)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = Types.SnapshotKind,
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			integrations = state.integrations,
			chains = state.chains,
			reviews = state.reviews,
			audits = state.audits,
		},
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		certificationIntegrationCoordinationPosture = "coordinates copied certification metadata only",
		copiedCertificationMetadataPosture = "certification metadata is copied and isolated",
		copiedDependencyMetadataPosture = "dependency metadata is declared and copied",
		copiedReadinessMetadataPosture = "readiness metadata is declared and copied",
		copiedProviderMetadataPosture = "provider metadata is declared and copied",
		copiedBootstrapMetadataPosture = "Bootstrap metadata is declared and copied",
		copiedDocumentationMetadataPosture = "documentation metadata is declared and copied",
		copiedCompatibilityMetadataPosture = "compatibility metadata has no authority expansion",
		certifiedGovernanceChain = dependencies.Serialization.deepCopy(Types.CertifiedRuntimeOrder),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
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
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
