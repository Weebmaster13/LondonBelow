--!strict
-- Isolated snapshots for Interaction Runtime Foundation.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		capturedAt = os.clock(),
		state = state.inspect(),
	})
	state.recordSnapshot({
		capturedAt = snapshot.capturedAt,
		interactionCount = snapshot.state.interactionCount,
		intentCount = snapshot.state.intentCount,
	})
	return snapshot
end

return Snapshots
