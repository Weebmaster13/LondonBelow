--!strict
-- Snapshot provider for Inventory Runtime Foundation.

local Serialization = require(script.Parent.InventorySerialization)
local Types = require(script.Parent.InventoryTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		profiles = inspected.profiles,
		items = inspected.items,
		slots = inspected.slots,
		ownership = inspected.ownership,
		capacity = inspected.capacity,
		eligibility = inspected.eligibility,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
