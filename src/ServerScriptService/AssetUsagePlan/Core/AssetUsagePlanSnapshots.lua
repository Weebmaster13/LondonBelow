--!strict

local State = require(script.Parent.AssetUsagePlanState)
local Types = require(script.Parent.AssetUsagePlanTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "AssetUsagePlanRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			definitions = state.definitions,
			contexts = state.contexts,
			constraints = state.constraints,
			dependencies = state.dependencies,
			budgets = state.budgets,
			accessibility = state.accessibility,
			audits = state.audits,
		},
		validationPosture = "schema data passed static validation before mutation",
		integrityPosture = {
			definitions = "usage intent records only",
			contexts = "context metadata only",
			constraints = "constraint summaries only",
			dependencies = "relationship metadata only",
			budgets = "declared limits only",
			accessibility = "accommodation metadata only",
			audits = "review summaries only",
		},
		noExecutionPosture = {
			assetLoad = false,
			assetPreload = false,
			instanceCreation = false,
			worldMutation = false,
			storageMutation = false,
			uiCreation = false,
			streamRun = false,
			modelSpawn = false,
			soundPlay = false,
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
