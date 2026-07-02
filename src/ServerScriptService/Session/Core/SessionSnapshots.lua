--!strict
-- Snapshot provider for Session Runtime Foundation.

local Serialization = require(script.Parent.SessionSerialization)
local Types = require(script.Parent.SessionTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		sessions = inspected.sessions,
		playerSessions = inspected.playerSessions,
		parties = inspected.parties,
		readiness = inspected.readiness,
		lifecycle = inspected.lifecycle,
		joinLeave = inspected.joinLeave,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
