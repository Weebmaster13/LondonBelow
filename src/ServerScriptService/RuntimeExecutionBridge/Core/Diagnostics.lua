--!strict

local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any): any
	local state = State.get()
	local validationOk, validationReason = Validation.validate()
	return {
		runtimeName = Types.RuntimeName,
		providerName = Types.RuntimeProviderName,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = state.lifecycleState,
		sessionImported = state.session ~= nil,
		evidencePrepared = state.evidence ~= nil,
		writerStatus = if state.writerResult ~= nil
			then state.writerResult.status
			else "NOT_EXECUTED",
		writerFailure = if state.writerResult ~= nil then state.writerResult.failure else nil,
		diagnosticCount = #state.diagnostics,
		assertionCount = #state.assertions,
		snapshotCount = #state.snapshots,
		validationOk = validationOk,
		validationReason = validationReason,
		noGameplayMutation = true,
		noClientAuthority = true,
		noPersistence = true,
		noNetworking = true,
		noCertificationAuthority = true,
		lastSelfChecks = Serialization.deepCopy(lifecycle.lastSelfChecks),
	}
end

function Diagnostics.validate(): (boolean, string?)
	return Validation.validate()
end

return Diagnostics
