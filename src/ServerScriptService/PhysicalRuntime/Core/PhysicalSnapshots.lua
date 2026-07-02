--!strict
-- Isolated snapshot provider for Physical Runtime Foundation.

local Serialization = require(script.Parent.PhysicalSerialization)
local Types = require(script.Parent.PhysicalTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		capturedAt = os.clock(),
		state = state.inspect(),
	})
	state.recordSnapshot({
		capturedAt = snapshot.capturedAt,
		registeredObjectCount = snapshot.state.registeredObjectCount,
		reservationCount = snapshot.state.reservationCount,
	})
	return snapshot
end

return Snapshots
