--!strict
-- Snapshot provider for Save / Journal / Identity runtime foundation.

local Serialization = require(script.Parent.SaveSerialization)

local Snapshots = {}

function Snapshots.capture(dependencies: { [string]: any })
	return Serialization.deepCopy({
		profiles = dependencies.Profiles.inspect(),
		checkpoints = dependencies.Checkpoints.inspect(),
		journal = dependencies.Journal.inspect(),
		memoryFragments = dependencies.MemoryFragments.inspect(),
		identity = dependencies.Identity.inspect(),
		replay = dependencies.Replay.inspect(),
		capturedAt = os.clock(),
	})
end

return Snapshots
