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
		authorizationLifecycleState = state.lifecycleState,
		policySummary = { count = #state.policies },
		ruleSummary = { count = #state.rules },
		decisionSummary = if state.decision ~= nil
			then {
				authorizationId = state.decision.authorizationId,
				decision = state.decision.decision,
				classification = state.decision.authorizationClassification,
			}
			else {},
		blockedRuntimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		diagnosticsIdentity = Types.RuntimeProviderName,
		audit = state.audit,
		noExecution = true,
		noRuntimeEvidence = true,
	}
	State.recordSnapshot(snapshot)
	return Serialization.deepCopy(snapshot)
end

return Snapshots
