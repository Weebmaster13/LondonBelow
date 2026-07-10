--!strict

local State = require(script.Parent.AssetGovernanceIntegrationState)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "assetGovernanceIntegrationRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			chains = state.chains,
			runtimeNodes = state.runtimeNodes,
			referenceReviews = state.referenceReviews,
			audits = state.audits,
		},
		validationPosture = "integration metadata passed validation before mutation",
		assetGovernanceIntegrationPosture = "read-only governance chain metadata evidence",
		readOnlyIntegrationPosture = "no upstream resolution, repair, mutation, or execution is performed",
		noExecutionPosture = {
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
		},
		noMutationPosture = {
			noWorldMutation = true,
			noStorageMutation = true,
			noUpstreamMutation = true,
			noRepairMutation = true,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
