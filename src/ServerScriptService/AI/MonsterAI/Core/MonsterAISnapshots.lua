--!strict
-- Snapshot provider for Phase 17 Monster AI execution foundation.

local Serialization = require(script.Parent.MonsterAISerialization)

local Snapshots = {}

function Snapshots.capture(registry: any, state: any)
	return Serialization.deepCopy({
		registry = registry.inspect(),
		state = state.inspect(),
		capturedAt = os.clock(),
		mode = "DryRunOnly",
	})
end

return Snapshots
