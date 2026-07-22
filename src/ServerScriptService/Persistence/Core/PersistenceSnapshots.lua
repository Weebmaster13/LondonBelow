--!strict
-- Snapshot provider for Data Persistence Boundary Foundation.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Snapshots = {}

function Snapshots.capture(state: any, runtime: any?)
	local inspected = state.inspect()
	local runtimeState = if runtime ~= nil then runtime.inspect() else nil
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		persistenceRuntimeAvailable = runtimeState ~= nil,
		persistenceRuntimePosture = "Healthy",
		registeredProviders = if runtimeState ~= nil
			then runtimeState.registry.registeredProviders
			else {},
		defaultProvider = if runtimeState ~= nil
			then runtimeState.registry.defaultProvider
			else nil,
		requestHistory = if runtimeState ~= nil
			then runtimeState.requestPipeline.requestHistory
			else {},
		failureHistory = if runtimeState ~= nil
			then runtimeState.requestPipeline.failureHistory
			else {},
		retryHistory = if runtimeState ~= nil then runtimeState.retryRuntime.history else {},
		counts = inspected.counts,
		requests = inspected.requests,
		packages = inspected.packages,
		migrations = inspected.migrations,
		policies = inspected.policies,
		failures = inspected.failures,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
