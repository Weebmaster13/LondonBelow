--!strict
-- Diagnostics for Session Runtime Foundation.

local Serialization = require(script.Parent.SessionSerialization)
local Types = require(script.Parent.SessionTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end

	return Serialization.deepCopy({
		health = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		limits = Types.Limits,
		mode = Types.Mode,
		serializationPosture = {
			rejectsInstances = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			exportsDeepCopies = true,
		},
		snapshotIsolationProof = {
			snapshotsAreDeepCopies = true,
			diagnosticsAreDeepCopies = true,
			unsafeRuntimeValuesAreSanitized = true,
		},
		noExecutionPosture = {
			noMatchmakingExecution = true,
			noTeleportExecution = true,
			noLobbyUi = true,
			noPartyGameplay = true,
			noSavePersistence = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noChapterContent = true,
		},
		recentValidationFailures = state.validationFailures,
	})
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	local state = dependencies.State.inspect()
	if state.counts.sessions > Types.Limits.MaxSessions then
		return false, "session count exceeds limit"
	end
	if state.counts.playerSessions > Types.Limits.MaxPlayerSessions then
		return false, "player session count exceeds limit"
	end
	if state.counts.parties > Types.Limits.MaxParties then
		return false, "party count exceeds limit"
	end
	return true, nil
end

return Diagnostics
