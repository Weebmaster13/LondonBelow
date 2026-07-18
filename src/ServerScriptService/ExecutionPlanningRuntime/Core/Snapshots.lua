--!strict

local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)

local Snapshots = {}

function Snapshots.capture(lifecycle: any): any
	local state = State.get()
	local snapshot = {
		snapshotKind = Types.SnapshotKind,
		runtimeName = Types.RuntimeName,
		providerName = Types.RuntimeProviderName,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		planningLifecycleState = state.lifecycleState,
		graph = state.graph,
		publication = state.publication,
		audit = state.audit,
		blockedRuntimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		noExecution = true,
		noRuntimeEvidence = true,
	}
	State.recordSnapshot(snapshot)
	return Serialization.deepCopy(snapshot)
end

return Snapshots
