--!strict

local State = require(script.Parent.AssetReadinessReviewState)
local Types = require(script.Parent.AssetReadinessReviewTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "AssetReadinessReviewRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			checklists = state.checklists,
			findings = state.findings,
			gates = state.gates,
			decisions = state.decisions,
			audits = state.audits,
		},
		validationPosture = "schema data passed static validation before mutation",
		readinessPosture = "readiness metadata only; no asset operations are represented as execution",
		noExecutionPosture = {
			assetLoad = false,
			assetPreload = false,
			contentStreaming = false,
			instanceCreation = false,
			worldMutation = false,
			storageMutation = false,
			uiCreation = false,
			vfxCreation = false,
			modelSpawn = false,
			audioLoad = false,
			animationLoad = false,
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
