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
		lifecycleState = state.lifecycleState,
		sessionId = if state.session ~= nil then state.session.sessionId else nil,
		events = state.events,
		assertions = state.assertions,
		diagnostics = state.diagnostics,
		writerResult = state.writerResult,
		cleanup = state.cleanup,
		noGameplayMutation = true,
		noClientAuthority = true,
		noPersistence = true,
		noNetworking = true,
	}
	State.recordSnapshot(snapshot)
	return Serialization.deepCopy(snapshot)
end

return Snapshots
