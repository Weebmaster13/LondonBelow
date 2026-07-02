--!strict
-- Snapshot provider for Developer Tooling Runtime Foundation.

local Serialization = require(script.Parent.ToolSerialization)
local Types = require(script.Parent.ToolTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		tools = inspected.tools,
		inspections = inspected.inspections,
		commands = inspected.commands,
		reports = inspected.reports,
		permissions = inspected.permissions,
		audits = inspected.audits,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
