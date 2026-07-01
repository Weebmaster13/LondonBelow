--!strict
-- Snapshot export for replay, debugging, and future persistence.

local Serialization = require(script.Parent.LivingCognitionSerialization)

local Snapshots = {}

function Snapshots.capture(state: any, registry: any)
	return Serialization.freezeForSnapshot({
		registry = registry.inspect(),
		state = state.inspect(),
		capturedAt = os.clock(),
	})
end

return Snapshots
