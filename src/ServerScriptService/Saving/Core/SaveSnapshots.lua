--!strict
-- Snapshot provider for Save / Journal / Identity runtime foundation.

local Serialization = require(script.Parent.SaveSerialization)

local Snapshots = {}

function Snapshots.capture(dependencies: { [string]: any })
	local saveRuntime = dependencies.SaveRuntime.inspect()
	return Serialization.deepCopy({
		saveRuntimeAvailable = saveRuntime.schemas.schemaCount > 0,
		saveRuntimePosture = {
			serverAuthoritative = true,
			writesDataStore = false,
			createsNetworking = false,
			mutatesGameplayFlow = false,
		},
		schemaVersion = 1,
		migrationVersion = 1,
		objectiveCount = if saveRuntime.serializer.lastSerialization ~= nil
			then saveRuntime.serializer.lastSerialization.objectiveCount
			else 0,
		checkpointCount = if saveRuntime.serializer.lastSerialization ~= nil
			then saveRuntime.serializer.lastSerialization.checkpointCount
			else 0,
		lastSerialization = saveRuntime.serializer.lastSerialization,
		lastValidation = dependencies.ValidationStatus,
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
