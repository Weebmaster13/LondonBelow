--!strict

local State = require(script.Parent.AssetExecutionBoundaryReviewState)
local Types = require(script.Parent.AssetExecutionBoundaryReviewTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "AssetExecutionBoundaryReviewRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			reviews = state.reviews,
			risks = state.risks,
			requirements = state.requirements,
			audits = state.audits,
		},
		validationPosture = "schema data passed static validation before mutation",
		boundaryReviewPosture = "future boundary review evidence only; no asset operation or client authority is granted",
		noExecutionPosture = {
			assetLoad = false,
			assetPreload = false,
			assetStreaming = false,
			assetApplication = false,
			assetPlayback = false,
			instanceCreation = false,
			worldMutation = false,
			storageMutation = false,
			uiCreation = false,
			vfxCreation = false,
			modelSpawn = false,
			gameplayRun = false,
			presentationRun = false,
			saveRun = false,
			remotes = false,
			clientAuthority = false,
			chapterContent = false,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
