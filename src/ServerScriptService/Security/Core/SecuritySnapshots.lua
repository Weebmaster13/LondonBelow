--!strict
-- Snapshot provider for Security / Anti-Exploit Boundary Runtime.

local Serialization = require(script.Parent.SecuritySerialization)
local Types = require(script.Parent.SecurityTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		trustPolicies = current.trustPolicies,
		authorityRules = current.authorityRules,
		exploitSignals = current.exploitSignals,
		clientRejections = current.clientRejections,
		remoteSafetyContracts = current.remoteSafetyContracts,
		rateLimits = current.rateLimits,
		audits = current.audits,
		noExecutionPosture = {
			noLiveAntiCheat = true,
			noExploitDetectionExecution = true,
			noBanKickEnforcement = true,
			noModeration = true,
			noPunishment = true,
			noClientMonitoring = true,
			noRemoteCreation = true,
			noRemoteInstanceHandling = true,
			noDataStoreReadsWrites = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noPlayerTracking = true,
			noWorldMutation = true,
			noGameplayExecution = true,
			noChapterContent = true,
		},
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
