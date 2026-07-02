--!strict
-- Snapshot provider for World Runtime Foundation.

local Serialization = require(script.Parent.WorldSerialization)
local Types = require(script.Parent.WorldTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		stores = inspected.stores,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
