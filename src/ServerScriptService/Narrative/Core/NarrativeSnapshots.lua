--!strict
-- Snapshot provider for Narrative Runtime foundation.

local Serialization = require(script.Parent.NarrativeSerialization)

local Snapshots = {}

function Snapshots.capture(state: any)
	return Serialization.deepCopy({
		state = state.inspect(),
		capturedAt = os.clock(),
		mode = "ServerAuthoritativeNarrativeFoundation",
	})
end

return Snapshots
