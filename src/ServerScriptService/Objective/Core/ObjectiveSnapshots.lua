--!strict
-- Snapshot provider for Objective Runtime Foundation.

local Serialization = require(script.Parent.ObjectiveSerialization)
local Types = require(script.Parent.ObjectiveTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		objectives = inspected.objectives,
		tasks = inspected.tasks,
		requirements = inspected.requirements,
		dependencies = inspected.dependencies,
		states = inspected.states,
		progressRecords = inspected.progressRecords,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
